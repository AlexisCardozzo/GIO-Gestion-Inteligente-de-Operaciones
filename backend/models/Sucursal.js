const pool = require('../config/database');

class Sucursal {
  static async createTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS sucursales (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        direccion VARCHAR(255) NOT NULL,
        usuario_id INTEGER NOT NULL,
        creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;
    try {
      await pool.query(query);
      console.log('✅ Tabla sucursales creada/verificada');
    } catch (error) {
      console.error('❌ Error creando tabla sucursales:', error);
      throw error;
    }
  }

  static async crear({ nombre, direccion, usuario_id }) {
    const query = `
      INSERT INTO sucursales (nombre, direccion, usuario_id)
      VALUES ($1, $2, $3)
      RETURNING id, nombre, direccion, usuario_id, creada_en;
    `;
    try {
      const result = await pool.query(query, [nombre, direccion, usuario_id]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error creando sucursal:', error);
      throw error;
    }
  }

  static async buscarPorUsuario(usuario_id) {
    const query = 'SELECT * FROM sucursales WHERE usuario_id = $1';
    try {
      const result = await pool.query(query, [usuario_id]);
      return result.rows;
    } catch (error) {
      console.error('❌ Error buscando sucursales por usuario:', error);
      throw error;
    }
  }

  static async buscarPorId(id) {
    const query = 'SELECT * FROM sucursales WHERE id = $1';
    try {
      const result = await pool.query(query, [id]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error buscando sucursal por ID:', error);
      throw error;
    }
  }
}

module.exports = Sucursal; 