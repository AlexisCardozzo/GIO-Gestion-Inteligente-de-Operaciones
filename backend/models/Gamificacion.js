const pool = require('../config/database');

class Gamificacion {
  static async createTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS gamificacion_puntos (
        id SERIAL PRIMARY KEY,
        usuario_id INTEGER NOT NULL,
        total_puntos INTEGER DEFAULT 0,
        total_ventas INTEGER DEFAULT 0,
        nivel INTEGER DEFAULT 1,
        ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT unique_usuario_gamificacion UNIQUE (usuario_id)
      );
    `;
    try {
      await pool.query(query);
      console.log('✅ Tabla gamificacion_puntos creada/verificada');
    } catch (error) {
      console.error('❌ Error creando tabla gamificacion_puntos:', error);
      throw error;
    }
  }

  static async actualizarPuntos(usuario_id, puntos_venta, monto_venta) {
    try {
      // Los puntos ya vienen calculados desde el controlador
      const puntos_ganados = puntos_venta;
      console.log(`🦉 Actualizando puntos de gamificación:`, {
        usuario_id,
        puntos_ganados,
        monto_venta
      });
      
      // Insertar o actualizar puntos del usuario
      const upsertQuery = `
        INSERT INTO gamificacion_puntos (usuario_id, total_puntos, total_ventas, ultima_actualizacion)
        VALUES ($1, $2, 1, NOW())
        ON CONFLICT (usuario_id) 
        DO UPDATE SET 
          total_puntos = gamificacion_puntos.total_puntos + $2,
          total_ventas = gamificacion_puntos.total_ventas + 1,
          ultima_actualizacion = NOW()
        RETURNING *;
      `;
      
      const result = await pool.query(upsertQuery, [usuario_id, puntos_ganados]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error actualizando puntos de gamificación:', error);
      throw error;
    }
  }

  static async obtenerProgreso(usuario_id) {
    try {
      if (!usuario_id) {
        console.log('⚠️ Error: obtenerProgreso llamado sin usuario_id');
        return {
          total_puntos: 0,
          total_ventas: 0,
          nivel: 1,
          ultima_actualizacion: new Date()
        };
      }

      console.log('🔍 Buscando progreso para usuario:', usuario_id);
      const query = `
        SELECT 
          total_puntos,
          total_ventas,
          nivel,
          ultima_actualizacion
        FROM gamificacion_puntos
        WHERE usuario_id = $1
      `;
      
      const result = await pool.query(query, [usuario_id]);
      console.log('📊 Resultado de la consulta:', result.rows);
      
      let progreso = result.rows[0] || {
        total_puntos: 0,
        total_ventas: 0,
        nivel: 1,
        ultima_actualizacion: new Date()
      };
      
      console.log('🦉 Progreso encontrado en BD:', progreso);
      return progreso;
    } catch (error) {
      console.error('❌ Error obteniendo progreso de gamificación:', error);
      throw error;
    }
  }
}

module.exports = Gamificacion;
