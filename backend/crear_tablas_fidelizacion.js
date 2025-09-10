const pool = require('./config/database');

async function crearTablasFidelizacion() {
  try {
    console.log('🚀 Creando tablas de fidelización...');

    // 1. Tabla de campañas de fidelización
    await pool.query(`
      CREATE TABLE IF NOT EXISTS fidelizacion_campanias (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(255) NOT NULL,
        descripcion TEXT,
        fecha_inicio DATE NOT NULL,
        fecha_fin DATE NOT NULL,
        activa BOOLEAN DEFAULT true,
        creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Tabla fidelizacion_campanias creada');

    // 2. Tabla de requisitos
    await pool.query(`
      CREATE TABLE IF NOT EXISTS fidelizacion_requisitos (
        id SERIAL PRIMARY KEY,
        campania_id INTEGER REFERENCES fidelizacion_campanias(id) ON DELETE CASCADE,
        tipo VARCHAR(50) NOT NULL CHECK (tipo IN ('compras', 'monto')),
        valor INTEGER NOT NULL,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Tabla fidelizacion_requisitos creada');

    // 3. Tabla de beneficios
    await pool.query(`
      CREATE TABLE IF NOT EXISTS fidelizacion_beneficios (
        id SERIAL PRIMARY KEY,
        campania_id INTEGER REFERENCES fidelizacion_campanias(id) ON DELETE CASCADE,
        tipo VARCHAR(50) NOT NULL CHECK (tipo IN ('descuento', 'producto')),
        valor VARCHAR(255) NOT NULL,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Tabla fidelizacion_beneficios creada');

    // 4. Tabla de clientes fieles (participación en campañas)
    await pool.query(`
      CREATE TABLE IF NOT EXISTS fidelizacion_clientes (
        id SERIAL PRIMARY KEY,
        cliente_id INTEGER REFERENCES clientes(id) ON DELETE CASCADE,
        campania_id INTEGER REFERENCES fidelizacion_campanias(id) ON DELETE CASCADE,
        puntos_acumulados INTEGER DEFAULT 0,
        progreso_actual INTEGER DEFAULT 0,
        fecha_inscripcion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(cliente_id, campania_id)
      )
    `);
    console.log('✅ Tabla fidelizacion_clientes creada');

    // 5. Verificar si existe la tabla clientes y agregar columnas si es necesario
    try {
      await pool.query(`
        ALTER TABLE clientes 
        ADD COLUMN IF NOT EXISTS ci_ruc VARCHAR(20),
        ADD COLUMN IF NOT EXISTS telefono VARCHAR(20),
        ADD COLUMN IF NOT EXISTS direccion TEXT,
        ADD COLUMN IF NOT EXISTS fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      `);
      console.log('✅ Columnas agregadas a tabla clientes');
    } catch (error) {
      console.log('⚠️ Error agregando columnas a clientes (puede que ya existan):', error.message);
    }

    // 6. Crear índices para mejor rendimiento
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_fidelizacion_campanias_activa ON fidelizacion_campanias(activa);
      CREATE INDEX IF NOT EXISTS idx_fidelizacion_requisitos_campania ON fidelizacion_requisitos(campania_id);
      CREATE INDEX IF NOT EXISTS idx_fidelizacion_beneficios_campania ON fidelizacion_beneficios(campania_id);
      CREATE INDEX IF NOT EXISTS idx_fidelizacion_clientes_campania ON fidelizacion_clientes(campania_id);
      CREATE INDEX IF NOT EXISTS idx_fidelizacion_clientes_cliente ON fidelizacion_clientes(cliente_id);
    `);
    console.log('✅ Índices creados');

    console.log('🎉 ¡Todas las tablas de fidelización han sido creadas exitosamente!');
    
    // Mostrar las tablas creadas
    const result = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name LIKE 'fidelizacion_%'
      ORDER BY table_name
    `);
    
    console.log('\n📋 Tablas de fidelización creadas:');
    result.rows.forEach(row => {
      console.log(`  - ${row.table_name}`);
    });

  } catch (error) {
    console.error('❌ Error creando tablas:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar el script
crearTablasFidelizacion(); 