const pool = require('./config/database');

async function agregarColumnasFaltantes() {
  try {
    console.log('🔧 Agregando columnas faltantes...');

    // 1. Agregar columnas faltantes a fidelizacion_clientes
    await pool.query(`
      ALTER TABLE fidelizacion_clientes 
      ADD COLUMN IF NOT EXISTS cumplio_requisitos BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS fecha_cumplimiento TIMESTAMP,
      ADD COLUMN IF NOT EXISTS estado VARCHAR(20) DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'completado'))
    `);
    console.log('✅ Columnas agregadas a fidelizacion_clientes');

    // 2. Agregar columnas faltantes a clientes
    await pool.query(`
      ALTER TABLE clientes 
      ADD COLUMN IF NOT EXISTS celular VARCHAR(20),
      ADD COLUMN IF NOT EXISTS email VARCHAR(100),
      ADD COLUMN IF NOT EXISTS fecha_nacimiento DATE,
      ADD COLUMN IF NOT EXISTS genero VARCHAR(10) CHECK (genero IN ('masculino', 'femenino', 'otro')),
      ADD COLUMN IF NOT EXISTS activo BOOLEAN DEFAULT true
    `);
    console.log('✅ Columnas agregadas a clientes');

    // 3. Verificar que las tablas tengan todas las columnas necesarias
    console.log('\n📋 Verificando estructura de tablas...');
    
    const tablas = [
      'fidelizacion_campanias',
      'fidelizacion_requisitos', 
      'fidelizacion_beneficios',
      'fidelizacion_clientes',
      'clientes'
    ];

    for (const tabla of tablas) {
      try {
        const result = await pool.query(`
          SELECT column_name, data_type, is_nullable
          FROM information_schema.columns 
          WHERE table_name = $1 
          ORDER BY ordinal_position
        `, [tabla]);
        
        console.log(`\n📊 Tabla: ${tabla}`);
        result.rows.forEach(col => {
          console.log(`  - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'YES' ? '(NULL)' : '(NOT NULL)'}`);
        });
      } catch (error) {
        console.log(`❌ Error verificando tabla ${tabla}:`, error.message);
      }
    }

    console.log('\n🎉 ¡Columnas agregadas exitosamente!');

  } catch (error) {
    console.error('❌ Error agregando columnas:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar el script
agregarColumnasFaltantes(); 