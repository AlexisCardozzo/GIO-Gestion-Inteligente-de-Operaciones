const pool = require('./config/database');

async function testBusquedaClientes() {
  try {
    console.log('🧪 Probando búsqueda de clientes...\n');

    // 1. Probar búsqueda por CI/RUC
    console.log('🔍 Búsqueda por CI/RUC "TEST_DIAG":');
    
    const busquedaCiRuc = await pool.query(`
      SELECT 
        id,
        COALESCE(ci_ruc, identificador) as ci_ruc,
        nombre,
        COALESCE(celular, telefono) as celular,
        direccion,
        email,
        fecha_registro,
        activo
      FROM clientes 
      WHERE activo = true
      AND (nombre ILIKE $1 OR ci_ruc ILIKE $1 OR identificador ILIKE $1 OR celular ILIKE $1 OR telefono ILIKE $1)
    `, ['%TEST_DIAG%']);
    
    if (busquedaCiRuc.rows.length > 0) {
      const cliente = busquedaCiRuc.rows[0];
      console.log(`✅ Cliente encontrado:`);
      console.log(`   - ID: ${cliente.id}`);
      console.log(`   - Nombre: ${cliente.nombre}`);
      console.log(`   - CI/RUC: ${cliente.ci_ruc}`);
      console.log(`   - Celular: ${cliente.celular}`);
    } else {
      console.log('❌ No se encontró cliente con CI/RUC TEST_DIAG');
    }

    // 2. Probar búsqueda por celular
    console.log('\n🔍 Búsqueda por celular "0999123456":');
    
    const busquedaCelular = await pool.query(`
      SELECT 
        id,
        COALESCE(ci_ruc, identificador) as ci_ruc,
        nombre,
        COALESCE(celular, telefono) as celular,
        direccion,
        email,
        fecha_registro,
        activo
      FROM clientes 
      WHERE activo = true
      AND (nombre ILIKE $1 OR ci_ruc ILIKE $1 OR identificador ILIKE $1 OR celular ILIKE $1 OR telefono ILIKE $1)
    `, ['%0999123456%']);
    
    if (busquedaCelular.rows.length > 0) {
      const cliente = busquedaCelular.rows[0];
      console.log(`✅ Cliente encontrado:`);
      console.log(`   - ID: ${cliente.id}`);
      console.log(`   - Nombre: ${cliente.nombre}`);
      console.log(`   - CI/RUC: ${cliente.ci_ruc}`);
      console.log(`   - Celular: ${cliente.celular}`);
    } else {
      console.log('❌ No se encontró cliente con celular 0999123456');
    }

    // 3. Probar búsqueda por nombre
    console.log('\n🔍 Búsqueda por nombre "Diagnóstico":');
    
    const busquedaNombre = await pool.query(`
      SELECT 
        id,
        COALESCE(ci_ruc, identificador) as ci_ruc,
        nombre,
        COALESCE(celular, telefono) as celular,
        direccion,
        email,
        fecha_registro,
        activo
      FROM clientes 
      WHERE activo = true
      AND (nombre ILIKE $1 OR ci_ruc ILIKE $1 OR identificador ILIKE $1 OR celular ILIKE $1 OR telefono ILIKE $1)
    `, ['%Diagnóstico%']);
    
    if (busquedaNombre.rows.length > 0) {
      const cliente = busquedaNombre.rows[0];
      console.log(`✅ Cliente encontrado:`);
      console.log(`   - ID: ${cliente.id}`);
      console.log(`   - Nombre: ${cliente.nombre}`);
      console.log(`   - CI/RUC: ${cliente.ci_ruc}`);
      console.log(`   - Celular: ${cliente.celular}`);
    } else {
      console.log('❌ No se encontró cliente con nombre Diagnóstico');
    }

    // 4. Mostrar todos los clientes para verificación
    console.log('\n👥 Todos los clientes disponibles:');
    
    const todosClientes = await pool.query(`
      SELECT 
        id,
        COALESCE(ci_ruc, identificador) as ci_ruc,
        nombre,
        COALESCE(celular, telefono) as celular,
        activo
      FROM clientes 
      ORDER BY id
    `);
    
    todosClientes.rows.forEach(cliente => {
      console.log(`  - ID ${cliente.id}: ${cliente.nombre} | CI/RUC: ${cliente.ci_ruc} | Celular: ${cliente.celular}`);
    });

    console.log('\n🎉 Pruebas de búsqueda completadas!');
    console.log('💡 Ahora el frontend debería funcionar correctamente');

  } catch (error) {
    console.error('❌ Error en pruebas:', error);
  } finally {
    await pool.end();
  }
}

testBusquedaClientes(); 