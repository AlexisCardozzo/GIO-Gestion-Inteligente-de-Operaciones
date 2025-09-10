const pool = require('../config/database');
const bcrypt = require('bcryptjs');

class Rol {
  static async createTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS roles (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(50) NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        tipo VARCHAR(20) NOT NULL DEFAULT 'Vendedor',
        sucursal_id INTEGER NOT NULL,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT unique_nombre_sucursal UNIQUE (nombre, sucursal_id)
      );
    `;
    try {
      await pool.query(query);
      console.log('✅ Tabla roles creada/verificada');
    } catch (error) {
      console.error('❌ Error creando tabla roles:', error);
      throw error;
    }
  }

  static async crear({ nombre, password, tipo = 'Vendedor', sucursal_id }) {
    const saltRounds = 10;
    const password_hash = await bcrypt.hash(password, saltRounds);
    const query = `
      INSERT INTO roles (nombre, password_hash, tipo, sucursal_id)
      VALUES ($1, $2, $3, $4)
      RETURNING id, nombre, tipo, sucursal_id, creado_en;
    `;
    try {
      const result = await pool.query(query, [nombre, password_hash, tipo, sucursal_id]);
      return result.rows[0];
    } catch (error) {
      if (error.code === '23505') {
        throw new Error('Ya existe un rol con ese nombre en esta sucursal');
      }
      console.error('❌ Error creando rol:', error);
      throw error;
    }
  }

  static async buscarPorSucursal(sucursal_id) {
    const query = 'SELECT id, nombre, tipo, sucursal_id, creado_en FROM roles WHERE sucursal_id = $1';
    try {
      const result = await pool.query(query, [sucursal_id]);
      return result.rows;
    } catch (error) {
      console.error('❌ Error buscando roles por sucursal:', error);
      throw error;
    }
  }

  static async autenticar({ nombre, password, sucursal_id }) {
    const query = 'SELECT * FROM roles WHERE nombre = $1 AND sucursal_id = $2';
    try {
      console.log('🔍 Buscando rol en BD:', { nombre, sucursal_id });
      const result = await pool.query(query, [nombre, sucursal_id]);
      console.log('📊 Resultado de búsqueda:', result.rows.length ? 'Rol encontrado' : 'Rol no encontrado');
      const rol = result.rows[0];
      if (!rol) return null;
      const valido = await bcrypt.compare(password, rol.password_hash);
      console.log('🔐 Validación de contraseña:', valido ? 'Correcta' : 'Incorrecta');
      if (!valido) return null;
      return { id: rol.id, nombre: rol.nombre, tipo: rol.tipo, sucursal_id: rol.sucursal_id };
    } catch (error) {
      console.error('❌ Error autenticando rol:', error);
      throw error;
    }
  }
}

module.exports = Rol; 