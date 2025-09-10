const pool = require('../config/database');

class FidelizacionCliente {
  static async createTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS fidelizacion_clientes (
        id SERIAL PRIMARY KEY,
        cliente_id INTEGER NOT NULL,
        campania_id INTEGER REFERENCES fidelizacion_campanias(id) ON DELETE CASCADE,
        cumplio_requisitos BOOLEAN DEFAULT false,
        beneficio_habilitado BOOLEAN DEFAULT false,
        fecha_habilitacion TIMESTAMP,
        puntos_acumulados INTEGER DEFAULT 0,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(cliente_id, campania_id)
      );
    `;
    try {
      await pool.query(query);
      console.log('✅ Tabla fidelizacion_clientes creada/verificada');
    } catch (error) {
      console.error('❌ Error creando tabla fidelizacion_clientes:', error);
      throw error;
    }
  }

  static async agregarClienteACampania(cliente_id, campania_id) {
    const query = `
      INSERT INTO fidelizacion_clientes (cliente_id, campania_id)
      VALUES ($1, $2)
      ON CONFLICT (cliente_id, campania_id) DO NOTHING
      RETURNING *
    `;
    try {
      const result = await pool.query(query, [cliente_id, campania_id]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error agregando cliente a campaña:', error);
      throw error;
    }
  }

  static async actualizarProgreso(cliente_id, campania_id, cumplio_requisitos, puntos = 0) {
    const query = `
      UPDATE fidelizacion_clientes 
      SET 
        cumplio_requisitos = $3,
        beneficio_habilitado = $3,
        puntos_acumulados = puntos_acumulados + $4,
        fecha_habilitacion = CASE WHEN $3 = true THEN NOW() ELSE fecha_habilitacion END
      WHERE cliente_id = $1 AND campania_id = $2
      RETURNING *
    `;
    try {
      const result = await pool.query(query, [cliente_id, campania_id, cumplio_requisitos, puntos]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error actualizando progreso:', error);
      throw error;
    }
  }
}

module.exports = FidelizacionCliente; 