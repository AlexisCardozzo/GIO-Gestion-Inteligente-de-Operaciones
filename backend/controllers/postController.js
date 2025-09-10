const pool = require('../config/database');

class PostController {
  // Crear un nuevo post
  static async crear(req, res) {
    const client = await pool.connect();
    try {
      const { contenido, categoria, emprendedor_id } = req.body;
      const usuario_id = req.user.userId;

      // Extraer hashtags del contenido
      const hashtagRegex = /#(\w+)/g;
      const hashtags = [...contenido.matchAll(hashtagRegex)].map(match => match[1]);

      await client.query('BEGIN');

      // Crear el post
      const postResult = await client.query(
        `INSERT INTO posts (usuario_id, contenido, categoria, emprendedor_id)
         VALUES ($1, $2, $3, $4)
         RETURNING *`,
        [usuario_id, contenido, categoria, emprendedor_id]
      );
      const post = postResult.rows[0];

      // Procesar hashtags
      for (const hashtag of hashtags) {
        // Insertar o actualizar hashtag
        const hashtagResult = await client.query(
          `INSERT INTO hashtags (nombre, uso_count)
           VALUES ($1, 1)
           ON CONFLICT (nombre)
           DO UPDATE SET uso_count = hashtags.uso_count + 1
           RETURNING id`,
          [hashtag.toLowerCase()]
        );

        // Relacionar hashtag con el post
        await client.query(
          `INSERT INTO posts_hashtags (post_id, hashtag_id)
           VALUES ($1, $2)`,
          [post.id, hashtagResult.rows[0].id]
        );
      }

      await client.query('COMMIT');
      res.status(201).json({
        success: true,
        data: {
          ...post,
          hashtags
        }
      });
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Error creando post:', error);
      res.status(500).json({ success: false, error: error.message });
    } finally {
      client.release();
    }
  }

  // Crear un comentario
  static async crearComentario(req, res) {
    const client = await pool.connect();
    try {
      const { contenido, post_padre_id } = req.body;
      const usuario_id = req.user.userId;

      await client.query('BEGIN');

      // Verificar que el post padre existe
      const postPadreResult = await client.query(
        'SELECT * FROM posts WHERE id = $1',
        [post_padre_id]
      );

      if (postPadreResult.rows.length === 0) {
        throw new Error('Post padre no encontrado');
      }

      // Crear el comentario
      const comentarioResult = await client.query(
        `INSERT INTO posts (usuario_id, contenido, is_comentario, post_padre_id)
         VALUES ($1, $2, true, $3)
         RETURNING *`,
        [usuario_id, contenido, post_padre_id]
      );

      // Crear notificación para el autor del post padre
      if (postPadreResult.rows[0].usuario_id !== usuario_id) {
        await client.query(
          `INSERT INTO notificaciones (usuario_id, tipo, contenido, referencia_id, referencia_tipo)
           VALUES ($1, 'comentario', $2, $3, 'post')`,
          [
            postPadreResult.rows[0].usuario_id,
            'Alguien comentó en tu post',
            post_padre_id
          ]
        );
      }

      await client.query('COMMIT');
      res.status(201).json({
        success: true,
        data: comentarioResult.rows[0]
      });
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Error creando comentario:', error);
      res.status(500).json({ success: false, error: error.message });
    } finally {
      client.release();
    }
  }

  // Obtener feed principal
  static async obtenerFeed(req, res) {
    try {
      const { page = 1, limit = 20, categoria } = req.query;
      const offset = (page - 1) * limit;

      let query = `
        SELECT 
          p.*,
          u.nombre as autor_nombre,
          u.email as autor_email,
          COUNT(l.id) as likes,
          COALESCE(json_agg(
            json_build_object(
              'id', h.id,
              'nombre', h.nombre
            )
          ) FILTER (WHERE h.id IS NOT NULL), '[]') as hashtags
        FROM posts p
        LEFT JOIN usuarios u ON p.usuario_id = u.id
        LEFT JOIN likes l ON p.id = l.post_id
        LEFT JOIN posts_hashtags ph ON p.id = ph.post_id
        LEFT JOIN hashtags h ON ph.hashtag_id = h.id
        WHERE p.estado = 'activo' AND p.is_comentario = false
      `;

      const values = [];
      if (categoria) {
        query += ' AND p.categoria = $1';
        values.push(categoria);
      }

      query += `
        GROUP BY p.id, u.nombre, u.email
        ORDER BY p.fecha_creacion DESC
        LIMIT $${values.length + 1} OFFSET $${values.length + 2}
      `;
      values.push(limit, offset);

      const result = await pool.query(query, values);
      
      // Para cada post, obtener sus comentarios
      const posts = await Promise.all(result.rows.map(async post => {
        const comentariosResult = await pool.query(
          `SELECT 
            p.*,
            u.nombre as autor_nombre,
            u.email as autor_email
           FROM posts p
           LEFT JOIN usuarios u ON p.usuario_id = u.id
           WHERE p.post_padre_id = $1 AND p.estado = 'activo'
           ORDER BY p.fecha_creacion
           LIMIT 3`,
          [post.id]
        );
        return {
          ...post,
          comentarios: comentariosResult.rows
        };
      }));

      res.json({
        success: true,
        data: posts,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          hasMore: posts.length === parseInt(limit)
        }
      });
    } catch (error) {
      console.error('Error obteniendo feed:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  }

  // Dar/quitar like a un post
  static async toggleLike(req, res) {
    const client = await pool.connect();
    try {
      const { post_id } = req.params;
      const usuario_id = req.user.userId;

      await client.query('BEGIN');

      // Verificar si ya existe el like
      const likeExistente = await client.query(
        'SELECT * FROM likes WHERE usuario_id = $1 AND post_id = $2',
        [usuario_id, post_id]
      );

      if (likeExistente.rows.length > 0) {
        // Quitar like
        await client.query(
          'DELETE FROM likes WHERE usuario_id = $1 AND post_id = $2',
          [usuario_id, post_id]
        );
      } else {
        // Dar like
        await client.query(
          'INSERT INTO likes (usuario_id, post_id) VALUES ($1, $2)',
          [usuario_id, post_id]
        );

        // Obtener autor del post
        const postResult = await client.query(
          'SELECT usuario_id FROM posts WHERE id = $1',
          [post_id]
        );

        // Crear notificación si el autor es diferente
        if (postResult.rows[0].usuario_id !== usuario_id) {
          await client.query(
            `INSERT INTO notificaciones (usuario_id, tipo, contenido, referencia_id, referencia_tipo)
             VALUES ($1, 'like', $2, $3, 'post')`,
            [
              postResult.rows[0].usuario_id,
              'A alguien le gustó tu post',
              post_id
            ]
          );
        }
      }

      await client.query('COMMIT');
      res.json({
        success: true,
        data: {
          liked: likeExistente.rows.length === 0
        }
      });
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Error toggle like:', error);
      res.status(500).json({ success: false, error: error.message });
    } finally {
      client.release();
    }
  }

  // Obtener notificaciones del usuario
  static async obtenerNotificaciones(req, res) {
    try {
      const usuario_id = req.user.userId;
      const { page = 1, limit = 20 } = req.query;
      const offset = (page - 1) * limit;

      const result = await pool.query(
        `SELECT *
         FROM notificaciones
         WHERE usuario_id = $1
         ORDER BY fecha_creacion DESC
         LIMIT $2 OFFSET $3`,
        [usuario_id, limit, offset]
      );

      // Marcar como leídas
      await pool.query(
        'UPDATE notificaciones SET leida = true WHERE usuario_id = $1 AND leida = false',
        [usuario_id]
      );

      res.json({
        success: true,
        data: result.rows,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          hasMore: result.rows.length === parseInt(limit)
        }
      });
    } catch (error) {
      console.error('Error obteniendo notificaciones:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  }

  // Obtener hashtags trending
  static async obtenerTrendingHashtags(req, res) {
    try {
      const result = await pool.query(
        `SELECT nombre, uso_count
         FROM hashtags
         ORDER BY uso_count DESC
         LIMIT 10`
      );

      res.json({
        success: true,
        data: result.rows
      });
    } catch (error) {
      console.error('Error obteniendo trending hashtags:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  }
}

module.exports = PostController;
