const pool = require('../config/database');

class FidelizacionRequisito {
  static async createTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS fidelizacion_requisitos (
        id SERIAL PRIMARY KEY,
        campania_id INTEGER REFERENCES fidelizacion_campanias(id) ON DELETE CASCADE,
        tipo VARCHAR(50) NOT NULL, -- compras, monto
        valor INTEGER NOT NULL,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;
    try {
      await pool.query(query);
      console.log('✅ Tabla fidelizacion_requisitos creada/verificada');
    } catch (error) {
      console.error('❌ Error creando tabla fidelizacion_requisitos:', error);
      throw error;
    }
  }
}

module.exports = FidelizacionRequisito; 