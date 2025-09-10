const pool = require('../config/database');

class Producto {
  static async listar(incluirInactivos = false, usuario_id = null) {
    let query = 'SELECT * FROM articulos';
    let conditions = [];
    let params = [];
    
    if (!incluirInactivos) {
      conditions.push('activo = true');
    }
    
    if (usuario_id) {
      conditions.push('usuario_id = $' + (params.length + 1));
      params.push(usuario_id);
    }
    
    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    query += ' ORDER BY nombre';
    const result = await pool.query(query, params);
    return result.rows;
  }

  static async buscarPorId(id) {
    const result = await pool.query('SELECT * FROM articulos WHERE id = $1', [id]);
    return result.rows[0];
  }

  static async crear({ nombre, codigo, precio_compra, precio_venta, iva, stock, usuario_id }) {
    // Verificar que el usuario_id esté presente
    if (!usuario_id) {
      throw new Error('Se requiere el ID del usuario para crear un producto');
    }
    
    const result = await pool.query(
      'INSERT INTO articulos (nombre, codigo, precio_compra, precio_venta, iva, stock, usuario_id) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
      [nombre, codigo, precio_compra, precio_venta, iva, stock, usuario_id]
    );
    return result.rows[0];
  }

  static async actualizar(id, { nombre, codigo, precio_compra, precio_venta, iva, stock }) {
    const result = await pool.query(
      'UPDATE articulos SET nombre = $1, codigo = $2, precio_compra = $3, precio_venta = $4, iva = $5, stock = $6 WHERE id = $7 RETURNING *',
      [nombre, codigo, precio_compra, precio_venta, iva, stock, id]
    );
    return result.rows[0];
  }

  static async eliminar(id) {
    // En lugar de eliminar físicamente, marcar como inactivo para preservar historial de ventas
    const result = await pool.query(
      'UPDATE articulos SET activo = false WHERE id = $1 RETURNING *', 
      [id]
    );
    return result.rows[0];
  }

  static async obtenerMovimientos(producto_id) {
    const result = await pool.query(
      'SELECT * FROM movimientos_stock WHERE articulo_id = $1 ORDER BY fecha_hora DESC',
      [producto_id]
    );
    return result.rows;
  }

  static async registrarMovimiento({ producto_id, tipo, cantidad, motivo }) {
    // Obtener stock actual
    const producto = await this.buscarPorId(producto_id);
    const stockActual = producto ? (producto.stock_minimo || 0) : 0;
    
    // Calcular nuevo stock
    const nuevoStock = tipo === 'entrada' ? stockActual + cantidad : stockActual - cantidad;
    
    // Actualizar stock del producto
    await pool.query(
      'UPDATE articulos SET stock_minimo = $1 WHERE id = $2',
      [nuevoStock, producto_id]
    );
    
    // Registrar movimiento
    const result = await pool.query(
      'INSERT INTO movimientos_stock (articulo_id, tipo_movimiento, cantidad, stock_antes, stock_despues, referencia, fecha_hora) VALUES ($1, $2, $3, $4, $5, $6, NOW()) RETURNING *',
      [producto_id, tipo, cantidad, stockActual, nuevoStock, motivo]
    );
    
    return result.rows[0];
  }

  static async obtenerStock(incluirInactivos = false, usuario_id = null) {
    let query = 'SELECT * FROM articulos';
    let conditions = [];
    let params = [];
    
    if (!incluirInactivos) {
      conditions.push('activo = true');
    }
    
    if (usuario_id) {
      conditions.push('usuario_id = $' + (params.length + 1));
      params.push(usuario_id);
    }
    
    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    query += ' ORDER BY nombre';
    const result = await pool.query(query, params);
    return result.rows.map(p => ({
      ...p,
      cantidad: p.stock_minimo || 0
    }));
  }
}

module.exports = Producto;