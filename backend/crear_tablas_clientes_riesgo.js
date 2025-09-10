const pool = require('./config/database');

async function crearTablasClientesRiesgo() {
  try {
    console.log('🔄 Creando tablas para sistema de clientes en riesgo...');

    // Tabla para clientes identificados en riesgo
    await pool.query(`
      CREATE TABLE IF NOT EXISTS clientes_riesgo (
        id SERIAL PRIMARY KEY,
        cliente_id INTEGER REFERENCES clientes(id) ON DELETE CASCADE,
        nivel_riesgo INTEGER CHECK (nivel_riesgo IN (1, 2, 3)),
        dias_sin_comprar INTEGER NOT NULL,
        producto_favorito VARCHAR(100),
        categoria_favorita VARCHAR(100),
        ultima_analisis TIMESTAMP DEFAULT NOW(),
        activo BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);
    console.log('✅ Tabla clientes_riesgo creada/verificada');

    // Tabla para historial de mensajes enviados
    await pool.query(`
      CREATE TABLE IF NOT EXISTS mensajes_retencion (
        id SERIAL PRIMARY KEY,
        cliente_id INTEGER REFERENCES clientes(id) ON DELETE CASCADE,
        nivel_riesgo INTEGER NOT NULL,
        mensaje_enviado TEXT NOT NULL,
        fecha_envio TIMESTAMP DEFAULT NOW(),
        respuesta_cliente BOOLEAN DEFAULT false,
        fecha_respuesta TIMESTAMP,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    console.log('✅ Tabla mensajes_retencion creada/verificada');

    // Tabla para análisis de productos favoritos
    await pool.query(`
      CREATE TABLE IF NOT EXISTS analisis_clientes (
        id SERIAL PRIMARY KEY,
        cliente_id INTEGER REFERENCES clientes(id) ON DELETE CASCADE,
        producto_id INTEGER REFERENCES articulos(id) ON DELETE CASCADE,
        producto_nombre VARCHAR(100) NOT NULL,
        categoria VARCHAR(100),
        frecuencia_compra INTEGER DEFAULT 1,
        ultima_compra TIMESTAMP,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(cliente_id, producto_id)
      )
    `);
    console.log('✅ Tabla analisis_clientes creada/verificada');

    // Crear índices para optimizar consultas
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_clientes_riesgo_cliente_id ON clientes_riesgo(cliente_id);
      CREATE INDEX IF NOT EXISTS idx_clientes_riesgo_nivel ON clientes_riesgo(nivel_riesgo);
      CREATE INDEX IF NOT EXISTS idx_clientes_riesgo_activo ON clientes_riesgo(activo);
      CREATE INDEX IF NOT EXISTS idx_mensajes_retencion_cliente_id ON mensajes_retencion(cliente_id);
      CREATE INDEX IF NOT EXISTS idx_mensajes_retencion_fecha ON mensajes_retencion(fecha_envio);
      CREATE INDEX IF NOT EXISTS idx_analisis_clientes_cliente_id ON analisis_clientes(cliente_id);
      CREATE INDEX IF NOT EXISTS idx_analisis_clientes_frecuencia ON analisis_clientes(frecuencia_compra DESC);
    `);
    console.log('✅ Índices creados/verificados');

    console.log('🎉 Todas las tablas de clientes en riesgo han sido creadas exitosamente!');
    
    // Verificar que las tablas existen
    const tablas = ['clientes_riesgo', 'mensajes_retencion', 'analisis_clientes'];
    for (const tabla of tablas) {
      const result = await pool.query(`
        SELECT EXISTS (
          SELECT FROM information_schema.tables 
          WHERE table_schema = 'public' 
          AND table_name = $1
        )
      `, [tabla]);
      
      if (result.rows[0].exists) {
        console.log(`✅ Tabla ${tabla} existe y está lista`);
      } else {
        console.log(`❌ Error: Tabla ${tabla} no se creó correctamente`);
      }
    }

  } catch (error) {
    console.error('❌ Error creando tablas de clientes en riesgo:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  crearTablasClientesRiesgo()
    .then(() => {
      console.log('✅ Script completado exitosamente');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Error en el script:', error);
      process.exit(1);
    });
}

module.exports = { crearTablasClientesRiesgo }; 