const pool = require('../config/database');
const bcrypt = require('bcryptjs');

class User {
  static async createTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS usuarios (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        apellido VARCHAR(100) NOT NULL,
        nombre_usuario VARCHAR(100) UNIQUE NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        rol VARCHAR(20) DEFAULT 'user',
        activo BOOLEAN DEFAULT true,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;
    try {
      await pool.query(query);
      console.log('✅ Tabla usuarios creada/verificada');
    } catch (error) {
      console.error('❌ Error creando tabla usuarios:', error);
      throw error;
    }
  }

  static async create(userData) {
    const { nombre, apellido, nombre_usuario, email, password, rol = 'user' } = userData;
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    const query = `
      INSERT INTO usuarios (nombre, apellido, nombre_usuario, email, password_hash, rol)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id, nombre, apellido, nombre_usuario, email, rol, creado_en;
    `;
    try {
      const result = await pool.query(query, [nombre, apellido, nombre_usuario, email, hashedPassword, rol]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error creando usuario:', error);
      throw error;
    }
  }

  static async findByEmail(email) {
    const query = 'SELECT * FROM usuarios WHERE email = $1 AND activo = true';
    try {
      const result = await pool.query(query, [email]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error buscando usuario por email:', error);
      throw error;
    }
  }

  static async findByUsername(nombre_usuario) {
    const query = 'SELECT * FROM usuarios WHERE nombre_usuario = $1 AND activo = true';
    try {
      const result = await pool.query(query, [nombre_usuario]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error buscando usuario por nombre de usuario:', error);
      throw error;
    }
  }

  static async findById(id) {
    const query = 'SELECT id, nombre, apellido, nombre_usuario, email, rol, creado_en FROM usuarios WHERE id = $1 AND activo = true';
    try {
      const result = await pool.query(query, [id]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error buscando usuario por ID:', error);
      throw error;
    }
  }

  static async validatePassword(user, password) {
    return await bcrypt.compare(password, user.password_hash);
  }
}

module.exports = User;