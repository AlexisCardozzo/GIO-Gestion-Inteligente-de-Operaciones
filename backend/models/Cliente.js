const pool = require('../config/database');

class Cliente {
  static async listar(filtro, usuario_id = null) {
    let query = `
      SELECT 
        id,
        COALESCE(ci_ruc, identificador) as ci_ruc,
        nombre,
        COALESCE(celular, telefono) as celular,
        direccion,
        email,
        fecha_registro,
        activo,
        verificado,
        score_credito,
        categoria_riesgo,
        ingresos_promedio_mensual,
        crecimiento_mensual,
        prestamos_solicitados,
        prestamos_aprobados,
        prestamos_pagados,
        prestamos_vencidos,
        usuario_id
      FROM clientes 
      WHERE activo = true
    `;
    let params = [];
    
    if (usuario_id) {
      query += ` AND usuario_id = $${params.length + 1}`;
      params.push(usuario_id);
    }

    if (filtro) {
      query += ' AND (nombre ILIKE $' + (params.length + 1) + ' OR ci_ruc ILIKE $' + (params.length + 1) + ' OR identificador ILIKE $' + (params.length + 1) + ' OR celular ILIKE $' + (params.length + 1) + ' OR telefono ILIKE $' + (params.length + 1) + ')';
      params.push(`%${filtro}%`);
    }
    
    const result = await pool.query(query, params);
    return result.rows;
  }

  static async obtenerHistorialCompras(clienteId, usuario_id = null) {
    let query = `SELECT v.id, v.fecha, v.total as monto, v.numero_factura as detalle
                 FROM ventas v
                 WHERE v.cliente_id = $1`;
    let params = [clienteId];
    
    if (usuario_id) {
      query += ` AND v.usuario_id = $${params.length + 1}`;
      params.push(usuario_id);
    }
    
    query += ` ORDER BY v.fecha DESC`;
    const result = await pool.query(query, params);
    return result.rows;
  }

  static async editar(id, { nombre, celular }, usuario_id = null) {
    // Eliminada la validación de duplicado de celular
    let query = 'UPDATE clientes SET nombre = $1, celular = $2 WHERE id = $3';
    let params = [nombre, celular, id];
    
    if (usuario_id) {
      query += ` AND usuario_id = $${params.length + 1}`;
      params.push(usuario_id);
    }
    
    query += ' RETURNING *';
    const result = await pool.query(query, params);
    return result.rows[0];
  }

  static async desactivar(id, usuario_id = null) {
    let query = 'UPDATE clientes SET activo = false WHERE id = $1';
    let params = [id];
    
    if (usuario_id) {
      query += ` AND usuario_id = $${params.length + 1}`;
      params.push(usuario_id);
    }
    
    query += ' RETURNING *';
    const result = await pool.query(query, params);
    return result.rows[0];
  }

  static async crear({ ci_ruc, nombre, celular, usuario_id }) {
    try {
      // Generar identificador único solo si no se proporciona ci_ruc
      let identificador = null;
      if (!ci_ruc) {
        // Generar identificador único basado en timestamp y nombre
        const timestamp = Date.now().toString().slice(-6);
        const nombreCorto = nombre.replace(/\s+/g, '').slice(0, 3).toUpperCase();
        identificador = `${nombreCorto}${timestamp}`;
      }

      const queryInsert = 'INSERT INTO clientes (identificador, ci_ruc, nombre, celular, activo, usuario_id) VALUES ($1, $2, $3, $4, true, $5) RETURNING *';
      const result = await pool.query(queryInsert, [identificador, ci_ruc, nombre, celular, usuario_id]);
      return result.rows[0];
    } catch (error) {
      // Manejo seguro del error para no tumbar el backend
      console.error('Error al crear cliente:', error);
      throw new Error('Error interno al crear cliente.');
    }
  }

  // Nuevos métodos para el sistema de préstamos
  static async obtenerPorId(id, usuario_id = null) {
    let query = `
      SELECT 
        id,
        nombre,
        email,
        telefono,
        direccion,
        ci_numero,
        ci_frente_url,
        ci_reverso_url,
        fecha_nacimiento,
        nivel_educativo,
        estado_civil,
        dependientes,
        tipo_negocio,
        antiguedad_negocio,
        empleados,
        ubicacion_negocio,
        ingresos_promedio_mensual,
        crecimiento_mensual,
        liquidez_promedio,
        frecuencia_transacciones,
        monto_promedio_venta,
        score_credito,
        categoria_riesgo,
        prestamos_solicitados,
        prestamos_aprobados,
        prestamos_pagados,
        prestamos_vencidos,
        verificado,
        fecha_verificacion,
        datos_para_venta,
        fecha_ultima_actualizacion_datos,
        activo
      FROM clientes 
      WHERE id = $1
    `;
    let params = [id];
    
    if (usuario_id) {
      query += ` AND usuario_id = $${params.length + 1}`;
      params.push(usuario_id);
    }
    
    const result = await pool.query(query, params);
    return result.rows[0];
  }

  static async actualizarDatosPrestamos(id, datos, usuario_id = null) {
    const campos = Object.keys(datos);
    const valores = Object.values(datos);
    const setClause = campos.map((campo, index) => `${campo} = $${index + 2}`).join(', ');
    
    let query = `UPDATE clientes SET ${setClause} WHERE id = $1`;
    let params = [id, ...valores];
    
    if (usuario_id) {
      query += ` AND usuario_id = $${params.length + 1}`;
      params.push(usuario_id);
    }
    
    query += ' RETURNING *';
    const result = await pool.query(query, params);
    return result.rows[0];
  }

  static async obtenerTodosVerificados(usuario_id = null) {
    let query = `
      SELECT 
        id,
        nombre,
        email,
        verificado,
        score_credito,
        categoria_riesgo,
        ingresos_promedio_mensual,
        datos_para_venta
      FROM clientes 
      WHERE verificado = true AND activo = true
    `;
    
    const params = [];
    
    if (usuario_id) {
      query += ` AND usuario_id = $1`;
      params.push(usuario_id);
    }
    
    const result = await pool.query(query, params);
    return result.rows;
  }
}

module.exports = Cliente;

