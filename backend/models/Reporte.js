const pool = require('../config/database');

class Reporte {
  static async createTable() {
    try {
      // Primero crear la tabla si no existe
      const createTableQuery = `
        CREATE TABLE IF NOT EXISTS reportes (
          id SERIAL PRIMARY KEY,
          fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          ventas INTEGER NOT NULL,
          ganancia_bruta NUMERIC NOT NULL,
          ganancia_neta NUMERIC NOT NULL,
          productos_vendidos JSONB NOT NULL,
          ventas_por_dia JSONB NOT NULL,
          eliminado BOOLEAN DEFAULT false,
          fecha_eliminacion TIMESTAMP,
          usuario_id INTEGER REFERENCES usuarios(id)
        );
      `;
      await pool.query(createTableQuery);
      
      // Luego agregar las columnas si no existen
      const alterQueries = [
        'ALTER TABLE reportes ADD COLUMN IF NOT EXISTS eliminado BOOLEAN DEFAULT false;',
        'ALTER TABLE reportes ADD COLUMN IF NOT EXISTS fecha_eliminacion TIMESTAMP;',
        'ALTER TABLE reportes ADD COLUMN IF NOT EXISTS usuario_id INTEGER REFERENCES usuarios(id);'
      ];
      
      for (const query of alterQueries) {
        try {
          await pool.query(query);
        } catch (error) {
          // Ignorar errores si las columnas ya existen
          console.log('Columna ya existe o error menor:', error.message);
        }
      }
      
      console.log('✅ Tabla reportes creada/verificada');
    } catch (error) {
      console.error('❌ Error creando tabla reportes:', error);
      throw error;
    }
  }

  static async crear({ ventas, ganancia_bruta, ganancia_neta, productos_vendidos, ventas_por_dia, usuario_id }) {
    const query = `
      INSERT INTO reportes (ventas, ganancia_bruta, ganancia_neta, productos_vendidos, ventas_por_dia, usuario_id)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *;
    `;
    const result = await pool.query(query, [ventas, ganancia_bruta, ganancia_neta, JSON.stringify(productos_vendidos), JSON.stringify(ventas_por_dia), usuario_id]);
    return result.rows[0];
  }

  static async listar(usuario_id) {
    // Siempre requerir usuario_id para garantizar privacidad
    if (!usuario_id) {
      console.error('Error: Se intentó listar reportes sin especificar usuario_id');
      return [];
    }
    
    const query = 'SELECT * FROM reportes WHERE eliminado = false AND usuario_id = $1 ORDER BY fecha DESC';
    const result = await pool.query(query, [usuario_id]);
    return result.rows;
  }

  static async obtenerPorId(id, usuario_id) {
    // Siempre requerir usuario_id para garantizar privacidad
    if (!usuario_id) {
      console.error('Error: Se intentó obtener reporte sin especificar usuario_id');
      return null;
    }
    
    const query = 'SELECT * FROM reportes WHERE id = $1 AND usuario_id = $2';
    const result = await pool.query(query, [id, usuario_id]);
    return result.rows[0];
  }

  static async moverAPapelera(ids, usuario_id) {
    // Siempre requerir usuario_id para garantizar privacidad
    if (!usuario_id) {
      console.error('Error: Se intentó mover a papelera sin especificar usuario_id');
      return;
    }
    
    const query = `UPDATE reportes SET eliminado = true, fecha_eliminacion = NOW() WHERE id = ANY($1::int[]) AND usuario_id = $2`;
    await pool.query(query, [ids, usuario_id]);
  }

  static async listarPapelera(usuario_id) {
    // Siempre requerir usuario_id para garantizar privacidad
    if (!usuario_id) {
      console.error('Error: Se intentó listar papelera sin especificar usuario_id');
      return [];
    }
    
    const query = 'SELECT * FROM reportes WHERE eliminado = true AND usuario_id = $1 ORDER BY fecha_eliminacion DESC';
    const result = await pool.query(query, [usuario_id]);
    return result.rows;
  }

  static async restaurar(ids, usuario_id) {
    // Siempre requerir usuario_id para garantizar privacidad
    if (!usuario_id) {
      console.error('Error: Se intentó restaurar reportes sin especificar usuario_id');
      return;
    }
    
    const query = `UPDATE reportes SET eliminado = false, fecha_eliminacion = NULL WHERE id = ANY($1::int[]) AND usuario_id = $2`;
    await pool.query(query, [ids, usuario_id]);
  }

  static async borrarDefinitivos(usuario_id) {
    // Siempre requerir usuario_id para garantizar privacidad
    if (!usuario_id) {
      console.error('Error: Se intentó borrar reportes definitivamente sin especificar usuario_id');
      return;
    }
    
    const query = `DELETE FROM reportes WHERE eliminado = true AND fecha_eliminacion < NOW() - INTERVAL '15 days' AND usuario_id = $1`;
    await pool.query(query, [usuario_id]);
  }

  static async borrarPorIds(ids, usuario_id) {
    // Siempre requerir usuario_id para garantizar privacidad
    if (!usuario_id) {
      console.error('Error: Se intentó borrar reportes por IDs sin especificar usuario_id');
      return;
    }
    
    const query = `DELETE FROM reportes WHERE id = ANY($1::int[]) AND usuario_id = $2`;
    await pool.query(query, [ids, usuario_id]);
  }
}

module.exports = Reporte;