const pool = require('../config/database');

class FidelizacionBeneficio {
  static async createTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS fidelizacion_beneficios (
        id SERIAL PRIMARY KEY,
        campania_id INTEGER REFERENCES fidelizacion_campanias(id) ON DELETE CASCADE,
        tipo VARCHAR(50) NOT NULL, -- descuento, producto
        valor VARCHAR(100) NOT NULL,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;
    try {
      await pool.query(query);
      console.log('✅ Tabla fidelizacion_beneficios creada/verificada');
    } catch (error) {
      console.error('❌ Error creando tabla fidelizacion_beneficios:', error);
      throw error;
    }
  }
}

module.exports = FidelizacionBeneficio; 