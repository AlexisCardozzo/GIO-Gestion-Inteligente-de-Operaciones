const pool = require('../config/database');

class Publicacion {
  static async createTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS publicaciones (
        id SERIAL PRIMARY KEY,
        emprendedor_id INTEGER REFERENCES emprendedores(id),
        tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('consejo', 'progreso', 'problema')),
        titulo VARCHAR(200) NOT NULL,
        contenido TEXT NOT NULL,
        imagen_url TEXT,
        estado VARCHAR(20) DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'reportado', 'eliminado')),
        likes INTEGER DEFAULT 0,
        comentarios INTEGER DEFAULT 0,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS comentarios (
        id SERIAL PRIMARY KEY,
        publicacion_id INTEGER REFERENCES publicaciones(id),
        usuario_id INTEGER REFERENCES usuarios(id),
        contenido TEXT NOT NULL,
        estado VARCHAR(20) DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'reportado', 'eliminado')),
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS reacciones (
        id SERIAL PRIMARY KEY,
        publicacion_id INTEGER REFERENCES publicaciones(id),
        usuario_id INTEGER REFERENCES usuarios(id),
        tipo VARCHAR(20) NOT NULL DEFAULT 'like',
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(publicacion_id, usuario_id)
      );

      CREATE INDEX IF NOT EXISTS idx_publicaciones_emprendedor ON publicaciones(emprendedor_id);
      CREATE INDEX IF NOT EXISTS idx_publicaciones_tipo ON publicaciones(tipo);
      CREATE INDEX IF NOT EXISTS idx_publicaciones_estado ON publicaciones(estado);
      CREATE INDEX IF NOT EXISTS idx_comentarios_publicacion ON comentarios(publicacion_id);
      CREATE INDEX IF NOT EXISTS idx_reacciones_publicacion ON reacciones(publicacion_id);
    `;

    try {
      await pool.query(query);
      console.log('✅ Tablas de publicaciones creadas/verificadas');
    } catch (error) {
      console.error('❌ Error creando tablas de publicaciones:', error);
      throw error;
    }
  }

  static async create(publicacionData) {
    const {
      emprendedor_id,
      tipo,
      titulo,
      contenido,
      imagen_url
    } = publicacionData;

    const query = `
      INSERT INTO publicaciones (
        emprendedor_id, tipo, titulo, contenido, imagen_url
      ) VALUES ($1, $2, $3, $4, $5)
      RETURNING *;
    `;

    try {
      const result = await pool.query(query, [
        emprendedor_id,
        tipo,
        titulo,
        contenido,
        imagen_url
      ]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error creando publicación:', error);
      throw error;
    }
  }

  static async findById(id) {
    const query = `
      SELECT p.*, e.nombre as emprendedor_nombre, e.apellido as emprendedor_apellido
      FROM publicaciones p
      JOIN emprendedores e ON p.emprendedor_id = e.id
      WHERE p.id = $1 AND p.estado = 'activo';
    `;

    try {
      const result = await pool.query(query, [id]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error buscando publicación:', error);
      throw error;
    }
  }

  static async listByType(tipo = null, limit = 20, offset = 0) {
    let query = `
      SELECT p.*, e.nombre as emprendedor_nombre, e.apellido as emprendedor_apellido,
             COUNT(DISTINCT c.id) as total_comentarios,
             COUNT(DISTINCT r.id) as total_likes
      FROM publicaciones p
      JOIN emprendedores e ON p.emprendedor_id = e.id
      LEFT JOIN comentarios c ON c.publicacion_id = p.id AND c.estado = 'activo'
      LEFT JOIN reacciones r ON r.publicacion_id = p.id
    `;
    let params = [];

    if (tipo) {
      query += ' WHERE p.tipo = $1 AND p.estado = \'activo\'';
      params = [tipo];
    } else {
      query += ' WHERE p.estado = \'activo\'';
    }

    query += `
      GROUP BY p.id, e.nombre, e.apellido
      ORDER BY p.fecha_creacion DESC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2};
    `;
    params.push(limit, offset);

    try {
      const result = await pool.query(query, params);
      return result.rows;
    } catch (error) {
      console.error('❌ Error listando publicaciones:', error);
      throw error;
    }
  }

  static async addComment(comentarioData) {
    const { publicacion_id, usuario_id, contenido } = comentarioData;

    const query = `
      WITH nuevo_comentario AS (
        INSERT INTO comentarios (publicacion_id, usuario_id, contenido)
        VALUES ($1, $2, $3)
        RETURNING *
      )
      UPDATE publicaciones
      SET comentarios = comentarios + 1,
          ultima_actualizacion = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING (SELECT * FROM nuevo_comentario);
    `;

    try {
      const result = await pool.query(query, [publicacion_id, usuario_id, contenido]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error agregando comentario:', error);
      throw error;
    }
  }

  static async toggleReaction(reaccionData) {
    const { publicacion_id, usuario_id } = reaccionData;

    const query = `
      WITH accion AS (
        INSERT INTO reacciones (publicacion_id, usuario_id)
        VALUES ($1, $2)
        ON CONFLICT (publicacion_id, usuario_id)
        DO DELETE
        RETURNING id
      )
      UPDATE publicaciones
      SET likes = likes + CASE WHEN EXISTS (SELECT 1 FROM accion) THEN 1 ELSE -1 END,
          ultima_actualizacion = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *;
    `;

    try {
      const result = await pool.query(query, [publicacion_id, usuario_id]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error actualizando reacción:', error);
      throw error;
    }
  }

  static async updateStatus(id, estado) {
    const query = `
      UPDATE publicaciones
      SET estado = $1,
          ultima_actualizacion = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING *;
    `;

    try {
      const result = await pool.query(query, [estado, id]);
      return result.rows[0];
    } catch (error) {
      console.error('❌ Error actualizando estado de publicación:', error);
      throw error;
    }
  }
}

module.exports = Publicacion;