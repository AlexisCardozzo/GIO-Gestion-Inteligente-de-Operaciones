require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function limpiarBaseDeDatos() {
  try {
    console.log('🧹 Iniciando limpieza completa de la base de datos...\n');
    
    // Deshabilitar verificación de foreign keys temporalmente
    await pool.query('SET session_replication_role = replica;');
    
    // Lista de tablas en orden (sin dependencias primero)
    const tablas = [
      'fidelizacion_clientes',
      'fidelizacion_beneficios', 
      'fidelizacion_requisitos',
      'fidelizacion_campanias',
      'ventas_detalle',
      'ventas',
      'stock_movimientos',
      'articulos',
      'clientes',
      'sucursales',
      'usuarios',
      'roles',
      'reportes'
    ];
    
    console.log('📋 Tablas a limpiar:');
    tablas.forEach((tabla, index) => {
      console.log(`  ${index + 1}. ${tabla}`);
    });
    
    console.log('\n🔄 Limpiando tablas...');
    
    // Limpiar cada tabla
    for (const tabla of tablas) {
      try {
        const result = await pool.query(`TRUNCATE TABLE ${tabla} RESTART IDENTITY CASCADE;`);
        console.log(`✅ ${tabla}: Limpiada`);
      } catch (error) {
        console.log(`⚠️ ${tabla}: ${error.message}`);
      }
    }
    
    // Rehabilitar verificación de foreign keys
    await pool.query('SET session_replication_role = DEFAULT;');
    
    console.log('\n🎯 Verificando limpieza...');
    
    // Verificar que las tablas estén vacías
    for (const tabla of tablas) {
      try {
        const result = await pool.query(`SELECT COUNT(*) as count FROM ${tabla};`);
        const count = parseInt(result.rows[0].count);
        console.log(`📊 ${tabla}: ${count} registros`);
      } catch (error) {
        console.log(`❌ ${tabla}: Error al verificar - ${error.message}`);
      }
    }
    
    console.log('\n✅ ¡Limpieza completada exitosamente!');
    console.log('💡 La base de datos está completamente limpia pero mantiene su estructura.');
    console.log('🔧 Puedes comenzar a crear nuevos datos desde cero.');
    
  } catch (error) {
    console.error('❌ Error durante la limpieza:', error);
  } finally {
    await pool.end();
  }
}

// Confirmación antes de ejecutar
console.log('⚠️  ADVERTENCIA: Este script eliminará TODOS los datos de la base de datos.');
console.log('📝 Mantendrá la estructura de las tablas pero todos los registros se perderán.');
console.log('🔄 Para continuar, ejecuta: node limpiar_db.js --confirm');
console.log('');

if (process.argv.includes('--confirm')) {
  limpiarBaseDeDatos();
} else {
  console.log('❌ Ejecución cancelada. Agrega --confirm para proceder.');
  process.exit(0);
} 