const pool = require('./config/database');

async function eliminarDatosPrueba() {
  try {
    console.log('🗑️ Eliminando datos de prueba...\n');

    // 1. Eliminar ventas de prueba
    console.log('1️⃣ Eliminando ventas de prueba...');
    const ventasResult = await pool.query(`
      DELETE FROM ventas 
      WHERE numero_factura LIKE 'FAC-%'
    `);
    console.log(`✅ ${ventasResult.rowCount} ventas de prueba eliminadas`);

    // 2. Eliminar clientes de prueba
    console.log('\n2️⃣ Eliminando clientes de prueba...');
    const clientesResult = await pool.query(`
      DELETE FROM clientes 
      WHERE identificador IN ('CLI001', 'CLI002', 'CLI003', 'CLI004', 'CLI005')
    `);
    console.log(`✅ ${clientesResult.rowCount} clientes de prueba eliminados`);

    // 3. Limpiar análisis de clientes en riesgo
    console.log('\n3️⃣ Limpiando análisis de clientes en riesgo...');
    const analisisResult = await pool.query(`
      DELETE FROM clientes_riesgo WHERE activo = true
    `);
    console.log(`✅ Análisis de clientes en riesgo limpiado`);

    // 4. Verificar estado final
    console.log('\n4️⃣ Verificando estado final...');
    const clientesCount = await pool.query('SELECT COUNT(*) FROM clientes WHERE activo = true');
    const ventasCount = await pool.query('SELECT COUNT(*) FROM ventas WHERE cliente_id IS NOT NULL');
    
    console.log(`📊 Total clientes reales: ${clientesCount.rows[0].count}`);
    console.log(`📊 Total ventas reales: ${ventasCount.rows[0].count}`);

    console.log('\n🎉 Datos de prueba eliminados exitosamente!');
    console.log('💡 Ahora el sistema usará solo tus clientes reales');

  } catch (error) {
    console.error('❌ Error eliminando datos de prueba:', error);
  } finally {
    await pool.end();
  }
}

eliminarDatosPrueba(); 