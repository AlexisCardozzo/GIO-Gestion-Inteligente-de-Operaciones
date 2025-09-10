const pool = require('./config/database');

async function crearTablasRedSocial() {
  try {
    console.log('🔧 Creando tablas para la Red Social...\n');

    // 1. Tabla de posts/historias
    console.log('📋 Creando tabla posts...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS posts (
        id SERIAL PRIMARY KEY,
        usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
        contenido TEXT NOT NULL,
        categoria VARCHAR(50),
        estado VARCHAR(20) DEFAULT 'activo' CHECK (estado IN ('activo', 'oculto', 'eliminado')),
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        likes_count INTEGER DEFAULT 0,
        comentarios_count INTEGER DEFAULT 0,
        is_comentario BOOLEAN DEFAULT FALSE,
        post_padre_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
        emprendedor_id INTEGER REFERENCES emprendedores(id) ON DELETE SET NULL
      )
    `);
    console.log('✅ Tabla posts creada');

    // 2. Tabla de likes
    console.log('📋 Creando tabla likes...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS likes (
        id SERIAL PRIMARY KEY,
        usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
        post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(usuario_id, post_id)
      )
    `);
    console.log('✅ Tabla likes creada');

    // 3. Tabla de hashtags
    console.log('📋 Creando tabla hashtags...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS hashtags (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(50) UNIQUE NOT NULL,
        uso_count INTEGER DEFAULT 1
      )
    `);
    console.log('✅ Tabla hashtags creada');

    // 4. Tabla de relación posts-hashtags
    console.log('📋 Creando tabla posts_hashtags...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS posts_hashtags (
        id SERIAL PRIMARY KEY,
        post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
        hashtag_id INTEGER REFERENCES hashtags(id) ON DELETE CASCADE,
        UNIQUE(post_id, hashtag_id)
      )
    `);
    console.log('✅ Tabla posts_hashtags creada');

    // 5. Tabla de notificaciones
    console.log('📋 Creando tabla notificaciones...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notificaciones (
        id SERIAL PRIMARY KEY,
        usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
        tipo VARCHAR(50) NOT NULL,
        contenido TEXT NOT NULL,
        leida BOOLEAN DEFAULT FALSE,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        referencia_id INTEGER,
        referencia_tipo VARCHAR(50)
      )
    `);
    console.log('✅ Tabla notificaciones creada');

    // 6. Crear índices para optimización
    console.log('📋 Creando índices...');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_posts_usuario ON posts(usuario_id)');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_posts_fecha ON posts(fecha_creacion)');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_likes_post ON likes(post_id)');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario ON notificaciones(usuario_id)');
    console.log('✅ Índices creados');

    // 7. Crear triggers para actualización automática de contadores
    console.log('📋 Creando triggers...');
    
    // Trigger para actualizar likes_count
    await pool.query(`
      CREATE OR REPLACE FUNCTION actualizar_likes_count()
      RETURNS TRIGGER AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          UPDATE posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
        ELSIF TG_OP = 'DELETE' THEN
          UPDATE posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
        END IF;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;

      DROP TRIGGER IF EXISTS trigger_actualizar_likes_count ON likes;
      CREATE TRIGGER trigger_actualizar_likes_count
        AFTER INSERT OR DELETE ON likes
        FOR EACH ROW
        EXECUTE FUNCTION actualizar_likes_count();
    `);

    // Trigger para actualizar comentarios_count
    await pool.query(`
      CREATE OR REPLACE FUNCTION actualizar_comentarios_count()
      RETURNS TRIGGER AS $$
      BEGIN
        IF TG_OP = 'INSERT' AND NEW.post_padre_id IS NOT NULL THEN
          UPDATE posts SET comentarios_count = comentarios_count + 1 WHERE id = NEW.post_padre_id;
        ELSIF TG_OP = 'DELETE' AND OLD.post_padre_id IS NOT NULL THEN
          UPDATE posts SET comentarios_count = comentarios_count - 1 WHERE id = OLD.post_padre_id;
        END IF;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;

      DROP TRIGGER IF EXISTS trigger_actualizar_comentarios_count ON posts;
      CREATE TRIGGER trigger_actualizar_comentarios_count
        AFTER INSERT OR DELETE ON posts
        FOR EACH ROW
        EXECUTE FUNCTION actualizar_comentarios_count();
    `);

    console.log('✅ Triggers creados');

    console.log('\n🎉 ¡Todas las tablas de la Red Social han sido creadas exitosamente!');
    console.log('\n📊 Resumen de tablas creadas:');
    console.log('  - posts');
    console.log('  - likes');
    console.log('  - hashtags');
    console.log('  - posts_hashtags');
    console.log('  - notificaciones');

  } catch (error) {
    console.error('❌ Error creando tablas:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar la creación
crearTablasRedSocial();
