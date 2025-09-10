const pool = require('../config/database');

class FidelizacionCampania {
  static async createTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS fidelizacion_campanias (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        descripcion TEXT,
        fecha_inicio DATE NOT NULL,
        fecha_fin DATE NOT NULL,
        activa BOOLEAN DEFAULT true,
        creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;
    try {
      await pool.query(query);
      console.log('✅ Tabla fidelizacion_campanias creada/verificada');
    } catch (error) {
      console.error('❌ Error creando tabla fidelizacion_campanias:', error);
      throw error;
    }
  }
}

module.exports = FidelizacionCampania; 