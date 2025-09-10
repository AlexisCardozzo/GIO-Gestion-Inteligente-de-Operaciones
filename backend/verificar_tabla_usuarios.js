const pool = require('./config/database');

async function verificarTablaUsuarios() {
  try {
    console.log('🔍 Verificando estructura de la tabla usuarios...');
    
    // Verificar si la tabla existe
    const tableExists = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'usuarios'
      );
    `);
    
    if (!tableExists.rows[0].exists) {
      console.log('❌ La tabla usuarios NO existe');
      return;
    }
    
    console.log('✅ La tabla usuarios existe');
    
    // Obtener estructura de la tabla
    const structure = await pool.query(`
      SELECT 
        column_name,
        data_type,
        is_nullable,
        column_default,
        character_maximum_length
      FROM information_schema.columns 
      WHERE table_name = 'usuarios' 
      AND table_schema = 'public'
      ORDER BY ordinal_position;
    `);
    
    console.log('\n📊 Estructura actual de la tabla usuarios:');
    structure.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'YES' ? '(NULL)' : '(NOT NULL)'} ${col.column_default ? `DEFAULT: ${col.column_default}` : ''}`);
    });
    
    // Verificar restricciones únicas
    const constraints = await pool.query(`
      SELECT 
        tc.constraint_name,
        tc.constraint_type,
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
    
    // Contar usuarios existentes
    const userCount = await pool.query('SELECT COUNT(*) FROM usuarios');
    console.log(`\n👥 Usuarios existentes: ${userCount.rows[0].count}`);
    
    // Mostrar algunos usuarios de ejemplo
    const sampleUsers = await pool.query('SELECT id, nombre_usuario, email, rol FROM usuarios LIMIT 5');
    if (sampleUsers.rows.length > 0) {
      console.log('\n📋 Usuarios de ejemplo:');
      sampleUsers.rows.forEach(user => {
        console.log(`  - ID: ${user.id}, Usuario: ${user.nombre_usuario}, Email: ${user.email}, Rol: ${user.rol}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Error verificando tabla:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar verificación
verificarTablaUsuarios(); 