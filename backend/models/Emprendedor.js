const pool = require('../config/database');

class Emprendedor {
  static async createTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS emprendedores (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES usuarios(id),
        nombre VARCHAR(100) NOT NULL,
        apellido VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        telefono VARCHAR(20) NOT NULL,
        historia TEXT NOT NULL,
        meta_descripcion TEXT,
        meta_recaudacion DECIMAL(10,2) DEFAULT 0,
        categoria VARCHAR(50),
        ubicacion VARCHAR(100),
        estado VARCHAR(20) DEFAULT 'pendiente',
        verificado BOOLEAN DEFAULT false,
        fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        fecha_verificacion TIMESTAMP,
        motivo_rechazo TEXT,
        total_donaciones DECIMAL(10,2) DEFAULT 0,
        cantidad_donaciones INTEGER DEFAULT 0,
        ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_emprendedores_estado ON emprendedores(estado);
      CREATE INDEX IF NOT EXISTS idx_emprendedores_verificado ON emprendedores(verificado);
    `;

    try {
      await pool.query(query);
      console.log('✅ Tabla emprendedores creada/verificada');
    } catch (error) {
      console.error('❌ Error creando tabla emprendedores:', error);
      throw error;
    }
  }

  static async create(emprendedorData) {
    const {
      user_id,
      nombre,
      apellido,
      email,
      telefono,
      historia,
      meta_descripcion,
      meta_recaudacion,
      categoria,
      ubicacion
    } = emprendedorData;

    const query = `
      INSERT INTO emprendedores (
        user_id, nombre, apellido, email, telefono,
        historia, meta_descripcion, meta_recaudacion,
        categoria, ubicacion
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING *;
    `;

    try {
      const result = await pool.query(query, [
        user_id, nombre, apellido, email, telefono,
        historia, meta_descripcion, meta_recaudacion,
        categoria, ubicacion
      ]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error creando emprendedor:', error);
      throw error;
    }
  }

  static async findById(id) {
    const query = 'SELECT * FROM emprendedores WHERE id = $1';
    try {
      const result = await pool.query(query, [id]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error buscando emprendedor:', error);
      throw error;
    }
  }

  static async findByUserId(userId) {
    const query = 'SELECT * FROM emprendedores WHERE user_id = $1';
    try {
      const result = await pool.query(query, [userId]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error buscando emprendedor por user_id:', error);
      throw error;
    }
  }

  static async updateStatus(id, { estado, motivo_rechazo = null }) {
    const query = `
      UPDATE emprendedores SET
        estado = $1,
        verificado = $2,
        fecha_verificacion = CURRENT_TIMESTAMP,
        motivo_rechazo = $3,
        ultima_actualizacion = CURRENT_TIMESTAMP
      WHERE id = $4
      RETURNING *;
    `;

    try {
      const result = await pool.query(query, [
        estado,
        estado === 'aprobado',
        motivo_rechazo,
        id
      ]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error actualizando estado del emprendedor:', error);
      throw error;
    }
  }

  static async listByStatus(estado = null) {
    let query = 'SELECT * FROM emprendedores ORDER BY fecha_registro DESC';
    let params = [];

    if (estado) {
      query = 'SELECT * FROM emprendedores WHERE estado = $1 ORDER BY fecha_registro DESC';
      params = [estado];
    }

    try {
      const result = await pool.query(query, params);
      return result.rows;
    } catch (error) {
      console.error('❌ Error listando emprendedores:', error);
      throw error;
    }
  }

  static async listVerified() {
    const query = `
      SELECT * FROM emprendedores
      WHERE verificado = TRUE AND estado = 'aprobado'
      ORDER BY fecha_registro DESC;
    `;

    try {
      const result = await pool.query(query);
      return result.rows;
    } catch (error) {
      console.error('❌ Error listando emprendedores verificados:', error);
      throw error;
    }
  }

  static async updateDonationStats(id, amount) {
    const query = `
      UPDATE emprendedores SET
        total_donaciones = total_donaciones + $1,
        cantidad_donaciones = cantidad_donaciones + 1,
        ultima_actualizacion = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING *;
    `;

    try {
      const result = await pool.query(query, [amount, id]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error actualizando estadísticas de donaciones:', error);
      throw error;
    }
  }
}

module.exports = Emprendedor;