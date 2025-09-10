const pool = require('../config/database');

class ConfiguracionTicket {
  static async createTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS configuracion_ticket (
        id SERIAL PRIMARY KEY,
        usuario_id INTEGER NOT NULL,
        nombre_negocio VARCHAR(100),
        direccion VARCHAR(200),
        telefono VARCHAR(20),
        mensaje_personalizado VARCHAR(200),
        mostrar_logo BOOLEAN DEFAULT false,
        mostrar_fecha BOOLEAN DEFAULT true,
        mostrar_numero_ticket BOOLEAN DEFAULT true,
        mostrar_vendedor BOOLEAN DEFAULT true,
        mostrar_cliente BOOLEAN DEFAULT true,
        pie_pagina VARCHAR(200),
        activo BOOLEAN DEFAULT true,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;
    try {
      await pool.query(query);
      console.log('✅ Tabla configuracion_ticket creada/verificada');
    } catch (error) {
      console.error('❌ Error creando tabla configuracion_ticket:', error);
      throw error;
    }
  }

  static async obtenerConfiguracion(usuario_id) {
    const query = 'SELECT * FROM configuracion_ticket WHERE usuario_id = $1 AND activo = true';
    const result = await pool.query(query, [usuario_id]);
    return result.rows[0] || null;
  }

  static async guardarConfiguracion({
    usuario_id,
    nombre_negocio,
    direccion,
    telefono,
    mensaje_personalizado,
    mostrar_logo,
    mostrar_fecha,
    mostrar_numero_ticket,
    mostrar_vendedor,
    mostrar_cliente,
    pie_pagina
  }) {
    // Verificar si ya existe una configuración para este usuario
    const existeConfig = await this.obtenerConfiguracion(usuario_id);
    
    let query;
    let params;
    
    if (existeConfig) {
      // Actualizar configuración existente
      query = `
        UPDATE configuracion_ticket 
        SET nombre_negocio = $1, 
            direccion = $2, 
            telefono = $3, 
            mensaje_personalizado = $4, 
            mostrar_logo = $5, 
            mostrar_fecha = $6, 
            mostrar_numero_ticket = $7, 
            mostrar_vendedor = $8, 
            mostrar_cliente = $9, 
            pie_pagina = $10
        WHERE usuario_id = $11 AND activo = true
        RETURNING *;
      `;
      params = [
        nombre_negocio,
        direccion,
        telefono,
        mensaje_personalizado,
        mostrar_logo,
        mostrar_fecha,
        mostrar_numero_ticket,
        mostrar_vendedor,
        mostrar_cliente,
        pie_pagina,
        usuario_id
      ];
    } else {
      // Crear nueva configuración
      query = `
        INSERT INTO configuracion_ticket (
          usuario_id, 
          nombre_negocio, 
          direccion, 
          telefono, 
          mensaje_personalizado, 
          mostrar_logo, 
          mostrar_fecha, 
          mostrar_numero_ticket, 
          mostrar_vendedor, 
          mostrar_cliente, 
          pie_pagina
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        RETURNING *;
      `;
      params = [
        usuario_id,
        nombre_negocio,
        direccion,
        telefono,
        mensaje_personalizado,
        mostrar_logo,
        mostrar_fecha,
        mostrar_numero_ticket,
        mostrar_vendedor,
        mostrar_cliente,
        pie_pagina
      ];
    }
    
    const result = await pool.query(query, params);
    return result.rows[0];
  }
}

module.exports = ConfiguracionTicket;