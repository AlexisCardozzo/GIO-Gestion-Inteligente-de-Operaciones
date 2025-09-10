const pool = require('../config/database');
const Articulo = require('./Articulo');

class Venta {
  static async createTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS ventas (
        id SERIAL PRIMARY KEY,
        sucursal_id INTEGER,
        usuario_id INTEGER,
        cliente_id INTEGER,
        fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        total NUMERIC NOT NULL,
        numero_factura VARCHAR(50)
      );
    `;
    try {
      await pool.query(query);
      console.log('✅ Tabla ventas creada/verificada');
    } catch (error) {
      console.error('❌ Error creando tabla ventas:', error);
      throw error;
    }
  }

  static async crear({ sucursal_id, usuario_id, cliente_id, fecha, total, numero_factura, forma_pago, items }) {
    const query = `INSERT INTO ventas (sucursal_id, usuario_id, cliente_id, fecha, total, numero_factura, forma_pago)
      VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *;`;
    const result = await pool.query(query, [sucursal_id, usuario_id, cliente_id, fecha || new Date(), total, numero_factura, forma_pago || 'efectivo']);
    const venta = result.rows[0];
    
    // Registrar detalle si hay items y obtener totales
    let totales = { totalVendidos: 0, gananciaBruta: 0, gananciaNeta: 0 };
    if (items && items.length > 0) {
      totales = await this.registrarDetalle(venta.id, items);
    }
    
    return { venta, totales };
  }

  static async listar(usuario_id = null) {
    let query = 'SELECT * FROM ventas';
    let params = [];
    
    if (usuario_id) {
      query += ' WHERE usuario_id = $1';
      params.push(usuario_id);
    }
    
    query += ' ORDER BY fecha DESC';
    const result = await pool.query(query, params);
    return result.rows;
  }

  static async buscarPorId(id, usuario_id = null) {
    let query = 'SELECT * FROM ventas WHERE id = $1';
    let params = [id];
    
    if (usuario_id) {
      query += ' AND usuario_id = $2';
      params.push(usuario_id);
    }
    
    const result = await pool.query(query, params);
    return result.rows[0];
  }

  static async contarVentas(usuario_id = null) {
    let query = 'SELECT COUNT(*) FROM ventas';
    let params = [];
    
    if (usuario_id) {
      query += ' WHERE usuario_id = $1';
      params.push(usuario_id);
    }
    
    const result = await pool.query(query, params);
    return parseInt(result.rows[0].count, 10);
  }

  static async obtenerTotal(usuario_id = null) {
    let query = 'SELECT COALESCE(SUM(total), 0) as total FROM ventas';
    let params = [];
    
    if (usuario_id) {
      query += ' WHERE usuario_id = $1';
      params.push(usuario_id);
    }
    
    const result = await pool.query(query, params);
    return parseFloat(result.rows[0].total);
  }

  static async createDetalleTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS ventas_detalle (
        id SERIAL PRIMARY KEY,
        venta_id INTEGER REFERENCES ventas(id) ON DELETE CASCADE,
        producto_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario NUMERIC NOT NULL,
        subtotal NUMERIC NOT NULL
      );
    `;
    try {
      await pool.query(query);
      console.log('✅ Tabla ventas_detalle creada/verificada');
    } catch (error) {
      console.error('❌ Error creando tabla ventas_detalle:', error);
      throw error;
    }
  }

  static async registrarDetalle(venta_id, items) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      let totalVendidos = 0;
      let gananciaBruta = 0;
      let gananciaNeta = 0;
      
      for (const item of items) {
        // Insertar detalle de venta
        const query = `INSERT INTO ventas_detalle (venta_id, producto_id, cantidad, precio_unitario, subtotal) VALUES ($1, $2, $3, $4, $5);`;
        await client.query(query, [venta_id, item.producto_id, item.cantidad, item.precio_unitario, item.subtotal]);
        
        // Actualizar stock y registrar movimiento (pasar el cliente para usar la misma transacción)
        await Articulo.registrarMovimientoStock({
          articulo_id: item.producto_id,
          tipo: 'salida',
          cantidad: item.cantidad,
          motivo: `venta_id=${venta_id}`,
        }, client);
        
        // Calcular sumas
        totalVendidos += item.cantidad;
        
        // Obtener datos del artículo para el cálculo de ganancias (pasar el cliente)
        const articulo = await Articulo.buscarPorId(item.producto_id, client);
        if (articulo) {
          const bruto = (item.precio_unitario - articulo.precio_compra) * item.cantidad;
          gananciaBruta += bruto;
          // Ganancia neta considerando IVA
          const iva = articulo.iva || 0;
          const neta = bruto - (bruto * iva / 100);
          gananciaNeta += neta;
        }
      }
      
      await client.query('COMMIT');
      return { totalVendidos, gananciaBruta, gananciaNeta };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  static async obtenerResumen(usuario_id = null) {
    try {
      // Obtener todas las ventas con sus detalles
      let query = `
        SELECT 
          v.id,
          v.total,
          dv.producto_id,
          dv.cantidad,
          dv.precio_unitario,
          a.precio_compra,
          a.iva
        FROM ventas v
        LEFT JOIN ventas_detalle dv ON v.id = dv.venta_id
        LEFT JOIN articulos a ON dv.producto_id = a.id
      `;
      
      let params = [];
      
      if (usuario_id) {
        query += ' WHERE v.usuario_id = $1';
        params.push(usuario_id);
      }
      
      query += ' ORDER BY v.fecha DESC';
      
      const result = await pool.query(query, params);
      
      let totalVentas = 0;
      let totalProductosVendidos = 0;
      let gananciaBruta = 0;
      let gananciaNeta = 0;
      const ventasContadas = new Set();
      
      for (const row of result.rows) {
        if (row.cantidad && row.precio_unitario && row.precio_compra) {
          // Contar productos vendidos (cantidad total de productos)
          totalProductosVendidos += parseInt(row.cantidad);
          
          // Contar ventas únicas (una sola vez por venta_id)
          if (!ventasContadas.has(row.id)) {
            totalVentas++;
            ventasContadas.add(row.id);
          }
          
          const bruto = (row.precio_unitario - row.precio_compra) * row.cantidad;
          gananciaBruta += bruto;
          const iva = row.iva || 0;
          const neta = bruto - (bruto * iva / 100);
          gananciaNeta += neta;
        }
      }
      
      return {
        totalVendidos: totalVentas, // Ahora cuenta el número de ventas, no productos
        totalProductosVendidos: totalProductosVendidos, // Cantidad total de productos vendidos
        gananciaBruta,
        gananciaNeta
      };
    } catch (error) {
      console.error('Error obteniendo resumen:', error);
      return { totalVendidos: 0, totalProductosVendidos: 0, gananciaBruta: 0, gananciaNeta: 0 };
    }
  }
}

module.exports = Venta;