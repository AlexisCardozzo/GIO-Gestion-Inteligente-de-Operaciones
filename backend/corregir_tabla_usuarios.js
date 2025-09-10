const pool = require('./config/database');

async function corregirTablaUsuarios() {
  try {
    console.log('🔧 Corrigiendo estructura de la tabla usuarios...');
    
    // 1. Agregar columna rol si no existe
    await pool.query(`
      ALTER TABLE usuarios 
      ADD COLUMN IF NOT EXISTS rol VARCHAR(20) DEFAULT 'user'
    `);
    console.log('✅ Columna rol agregada');
    
    // 2. Eliminar columna correo duplicada (si existe)
    try {
      await pool.query('ALTER TABLE usuarios DROP COLUMN IF EXISTS correo');
      console.log('✅ Columna correo duplicada eliminada');
    } catch (error) {
      console.log('⚠️ No se pudo eliminar correo:', error.message);
    }
    
    // 3. Asegurar que las columnas requeridas tengan las restricciones correctas
    await pool.query(`
      ALTER TABLE usuarios 
      ALTER COLUMN nombre_usuario SET NOT NULL,
      ALTER COLUMN apellido SET NOT NULL,
      ALTER COLUMN email SET NOT NULL
    `);
    console.log('✅ Restricciones NOT NULL aplicadas');
    
    // 4. Agregar restricciones únicas si no existen
    try {
      await pool.query('ALTER TABLE usuarios ADD CONSTRAINT usuarios_nombre_usuario_key UNIQUE (nombre_usuario)');
      console.log('✅ Restricción única en nombre_usuario agregada');
    } catch (error) {
      console.log('⚠️ Restricción única en nombre_usuario ya existe');
    }
    
    try {
      await pool.query('ALTER TABLE usuarios ADD CONSTRAINT usuarios_email_key UNIQUE (email)');
      console.log('✅ Restricción única en email agregada');
    } catch (error) {
      console.log('⚠️ Restricción única en email ya existe');
    }
    
    // 5. Verificar estructura final
    const structure = await pool.query(`
      SELECT 
        column_name,
        data_type,
        is_nullable,
        column_default
      FROM information_schema.columns 
      WHERE table_name = 'usuarios' 
      AND table_schema = 'public'
      ORDER BY ordinal_position;
    `);
    
    console.log('\n📊 Estructura final de la tabla usuarios:');
    structure.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'YES' ? '(NULL)' : '(NOT NULL)'} ${col.column_default ? `DEFAULT: ${col.column_default}` : ''}`);
    });
    
    // 6. Verificar restricciones únicas
    const constraints = await pool.query(`
      SELECT 
        tc.constraint_name,
        kcu.column_name
      FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
      WHERE tc.table_name = 'usuarios' 
      AND tc.table_schema = 'public'
      AND tc.constraint_type = 'UNIQUE';
    `);
    
    console.log('\n🔒 Restricciones únicas:');
    constraints.rows.forEach(constraint => {
      console.log(`  - ${constraint.constraint_name}: ${constraint.column_name}`);
    });
    
    console.log('\n🎉 ¡Estructura de tabla usuarios corregida exitosamente!');
    
  } catch (error) {
    console.error('❌ Error corrigiendo tabla:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar corrección
corregirTablaUsuarios(); 