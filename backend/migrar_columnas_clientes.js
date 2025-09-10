const pool = require('./config/database');

async function migrarColumnasClientes() {
  try {
    console.log('🔄 Migrando columnas de clientes...\n');

    // 1. Verificar estado actual
    console.log('📊 Estado actual de la tabla clientes:');
    
    const estadoActual = await pool.query(`
      SELECT 
        COUNT(*) as total_clientes,
        COUNT(ci_ruc) as con_ci_ruc,
        COUNT(identificador) as con_identificador,
        COUNT(celular) as con_celular,
        COUNT(telefono) as con_telefono
      FROM clientes
    `);
    
    const stats = estadoActual.rows[0];
    console.log(`  - Total clientes: ${stats.total_clientes}`);
    console.log(`  - Con ci_ruc: ${stats.con_ci_ruc}`);
    console.log(`  - Con identificador: ${stats.con_identificador}`);
    console.log(`  - Con celular: ${stats.con_celular}`);
    console.log(`  - Con telefono: ${stats.con_telefono}`);

    // 2. Migrar identificador a ci_ruc donde sea necesario
    console.log('\n🔄 Migrando identificador → ci_ruc...');
    
    const migracionIdentificador = await pool.query(`
      UPDATE clientes 
      SET ci_ruc = identificador 
      WHERE ci_ruc IS NULL AND identificador IS NOT NULL
    `);
    
    console.log(`✅ Migrados ${migracionIdentificador.rowCount} registros de identificador a ci_ruc`);

    // 3. Migrar telefono a celular donde sea necesario
    console.log('\n🔄 Migrando telefono → celular...');
    
    const migracionTelefono = await pool.query(`
      UPDATE clientes 
      SET celular = telefono 
      WHERE celular IS NULL AND telefono IS NOT NULL
    `);
    
    console.log(`✅ Migrados ${migracionTelefono.rowCount} registros de telefono a celular`);

    // 4. Verificar estado final
    console.log('\n📊 Estado final después de la migración:');
    
    const estadoFinal = await pool.query(`
      SELECT 
        COUNT(*) as total_clientes,
        COUNT(ci_ruc) as con_ci_ruc,
        COUNT(identificador) as con_identificador,
        COUNT(celular) as con_celular,
        COUNT(telefono) as con_telefono
      FROM clientes
    `);
    
    const statsFinal = estadoFinal.rows[0];
    console.log(`  - Total clientes: ${statsFinal.total_clientes}`);
    console.log(`  - Con ci_ruc: ${statsFinal.con_ci_ruc}`);
    console.log(`  - Con identificador: ${statsFinal.con_identificador}`);
    console.log(`  - Con celular: ${statsFinal.con_celular}`);
    console.log(`  - Con telefono: ${statsFinal.con_telefono}`);

    // 5. Mostrar algunos ejemplos de clientes
    console.log('\n👥 Ejemplos de clientes:');
    
    const ejemplos = await pool.query(`
      SELECT 
        id,
        nombre,
        COALESCE(ci_ruc, identificador) as ci_ruc,
        COALESCE(celular, telefono) as celular,
        activo
      FROM clientes 
      ORDER BY id 
      LIMIT 5
    `);
    
    ejemplos.rows.forEach(cliente => {
      console.log(`  - ID ${cliente.id}: ${cliente.nombre} | CI/RUC: ${cliente.ci_ruc} | Celular: ${cliente.celular}`);
    });

    console.log('\n🎉 Migración completada exitosamente!');
    console.log('💡 Ahora el frontend debería mostrar correctamente nombre y celular al buscar por CI/RUC');

  } catch (error) {
    console.error('❌ Error en migración:', error);
  } finally {
    await pool.end();
  }
}

migrarColumnasClientes(); 