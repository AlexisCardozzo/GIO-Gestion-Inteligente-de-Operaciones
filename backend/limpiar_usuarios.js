const pool = require('./config/database');

async function limpiarUsuarios() {
  try {
    console.log('🧹 Limpiando tabla de usuarios...');
    
    // Contar usuarios antes
    const countBefore = await pool.query('SELECT COUNT(*) FROM usuarios');
    console.log(`📊 Usuarios antes: ${countBefore.rows[0].count}`);
    
    // Limpiar tabla
    await pool.query('TRUNCATE TABLE usuarios RESTART IDENTITY CASCADE');
    
    // Contar usuarios después
    const countAfter = await pool.query('SELECT COUNT(*) FROM usuarios');
    console.log(`📊 Usuarios después: ${countAfter.rows[0].count}`);
    
    console.log('✅ Tabla de usuarios limpiada exitosamente');
    
  } catch (error) {
    console.error('❌ Error limpiando usuarios:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar solo si se confirma
console.log('⚠️  ADVERTENCIA: Esto eliminará TODOS los usuarios de la base de datos');
console.log('¿Estás seguro de que quieres continuar? (Ctrl+C para cancelar)');

// Esperar 3 segundos antes de ejecutar
setTimeout(() => {
  console.log('Ejecutando limpieza...');
  limpiarUsuarios();
}, 3000); 