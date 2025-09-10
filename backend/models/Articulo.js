const pool = require('../config/database');

class Articulo {
  static async listar(filtro, incluirInactivos = false, usuario_id = null) {
    let query = 'SELECT * FROM articulos';
    let params = [];
    let conditions = [];
    
    // Por defecto solo mostrar activos, a menos que se especifique lo contrario
    if (!incluirInactivos) {
      conditions.push('activo = true');
    }
    
    // Filtrar por usuario_id si se proporciona
    if (usuario_id) {
      conditions.push('usuario_id = $' + (params.length + 1));
      params.push(usuario_id);
    }
    
    if (filtro) {
      conditions.push('(nombre ILIKE $' + (params.length + 1) + ' OR codigo ILIKE $' + (params.length + 1) + ')');
      params.push(`%${filtro}%`);
    }
    
    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    query += ' ORDER BY nombre';
    const result = await pool.query(query, params);
    return result.rows;
  }

  static async buscarPorId(id, client = null, usuario_id = null) {
    let query = 'SELECT * FROM articulos WHERE id = $1';
    let params = [id];
    
    if (usuario_id) {
      query += ' AND usuario_id = $2';
      params.push(usuario_id);
    }
    
    const result = client ? await client.query(query, params) : await pool.query(query, params);
    return result.rows[0];
  }

  static async crear({ nombre, codigo, categoria_id, precio_compra, precio_venta, stock_minimo, activo, iva, usuario_id }) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      // Insertar el artículo con stock inicial y usuario_id
      const result = await client.query(
        'INSERT INTO articulos (nombre, codigo, categoria_id, precio_compra, precio_venta, stock_minimo, activo, iva, usuario_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *',
        [nombre, codigo, categoria_id || null, precio_compra, precio_venta, stock_minimo || 0, activo !== undefined ? activo : true, iva || 10, usuario_id]
      );
      const articulo = result.rows[0];
      
      // Si hay stock inicial, registrar el movimiento de entrada
      if (stock_minimo && stock_minimo > 0) {
        await client.query(
          'INSERT INTO movimientos_stock (articulo_id, tipo_movimiento, cantidad, stock_antes, stock_despues, referencia, fecha_hora) VALUES ($1, $2, $3, $4, $5, $6, NOW())',
          [articulo.id, 'entrada', stock_minimo, 0, stock_minimo, 'Stock inicial']
        );
      }
      
      await client.query('COMMIT');
      return articulo;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  static async registrarMovimientoStock({ articulo_id, tipo, cantidad, motivo }, client = null) {
    const useTransaction = !client;
    if (useTransaction) {
      client = await pool.connect();
    }
    
    try {
      if (useTransaction) {
        await client.query('BEGIN');
      }
      
      // Obtener el stock actual antes del movimiento (con bloqueo)
      const result = await client.query('SELECT stock_minimo FROM articulos WHERE id = $1 FOR UPDATE', [articulo_id]);
      const stockAntes = result.rows[0] ? parseInt(result.rows[0].stock_minimo) : 0;
      const stockDespues = tipo === 'entrada' ? stockAntes + cantidad : stockAntes - cantidad;
      
      // Insertar el movimiento en la tabla movimientos_stock
      await client.query(
        'INSERT INTO movimientos_stock (articulo_id, tipo_movimiento, cantidad, stock_antes, stock_despues, referencia, fecha_hora) VALUES ($1, $2, $3, $4, $5, $6, NOW())',
        [articulo_id, tipo, cantidad, stockAntes, stockDespues, motivo]
      );
      
      // Actualizar el stock_minimo en articulos
      await client.query('UPDATE articulos SET stock_minimo = $1 WHERE id = $2', [stockDespues, articulo_id]);
      
      if (useTransaction) {
        await client.query('COMMIT');
      }
    } catch (error) {
      if (useTransaction) {
        await client.query('ROLLBACK');
      }
      throw error;
    } finally {
      if (useTransaction) {
        client.release();
      }
    }
  }

  static async actualizar(id, { nombre, codigo, categoria_id, precio_compra, precio_venta, stock_minimo, activo, iva }, usuario_id = null) {
    let query = 'UPDATE articulos SET nombre = $1, codigo = $2, categoria_id = $3, precio_compra = $4, precio_venta = $5, stock_minimo = $6, activo = $7, iva = $8 WHERE id = $9';
    let params = [nombre, codigo, categoria_id || null, precio_compra, precio_venta, stock_minimo || 0, activo !== undefined ? activo : true, iva || 10, id];
    
    if (usuario_id) {
      query += ' AND usuario_id = $10';
      params.push(usuario_id);
    }
    
    query += ' RETURNING *';
    
    const result = await pool.query(query, params);
    return result.rows[0];
  }

  static async eliminar(id, usuario_id = null) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      // Verificar si el producto existe y pertenece al usuario
      let query = 'SELECT * FROM articulos WHERE id = $1';
      let params = [id];
      
      if (usuario_id) {
        query += ' AND usuario_id = $2';
        params.push(usuario_id);
      }
      
      const producto = await client.query(query, params);
      if (producto.rows.length === 0) {
        return null;
      }
      
      // Eliminar movimientos de stock asociados
      await client.query('DELETE FROM movimientos_stock WHERE articulo_id = $1', [id]);
      
      // Eliminar detalles de ventas asociados
      await client.query('DELETE FROM ventas_detalle WHERE producto_id = $1', [id]);
      
      // Eliminar el producto completamente
      let deleteQuery = 'DELETE FROM articulos WHERE id = $1';
      let deleteParams = [id];
      
      if (usuario_id) {
        deleteQuery += ' AND usuario_id = $2';
        deleteParams.push(usuario_id);
      }
      
      deleteQuery += ' RETURNING *';
      
      const result = await client.query(deleteQuery, deleteParams);
      
      await client.query('COMMIT');
      return result.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

module.exports = Articulo;