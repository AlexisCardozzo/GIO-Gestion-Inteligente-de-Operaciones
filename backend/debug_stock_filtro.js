const pool = require('./config/database');

async function debugStockFiltro() {
  try {
    console.log('🔍 Debuggeando filtro de productos activos...\n');

    // 1. Verificar todos los productos
    console.log('📊 Todos los productos en la base de datos:');
    const todosProductos = await pool.query('SELECT id, nombre, activo FROM articulos ORDER BY id');
    todosProductos.rows.forEach(p => {
      console.log(`  - ID ${p.id}: ${p.nombre} (activo: ${p.activo})`);
    });

    // 2. Verificar productos activos
    console.log('\n📊 Productos activos:');
    const productosActivos = await pool.query('SELECT id, nombre, activo FROM articulos WHERE activo = true ORDER BY id');
    productosActivos.rows.forEach(p => {
      console.log(`  - ID ${p.id}: ${p.nombre} (activo: ${p.activo})`);
    });

    // 3. Verificar productos inactivos
    console.log('\n📊 Productos inactivos:');
    const productosInactivos = await pool.query('SELECT id, nombre, activo FROM articulos WHERE activo = false ORDER BY id');
    productosInactivos.rows.forEach(p => {
      console.log(`  - ID ${p.id}: ${p.nombre} (activo: ${p.activo})`);
    });

    // 4. Probar el método listar() directamente
    console.log('\n🔍 Probando método listar()...');
    const Producto = require('./models/Producto');
    
    const productosListados = await Producto.listar();
    console.log(`  - Productos listados (solo activos): ${productosListados.length}`);
    productosListados.forEach(p => {
      console.log(`    - ID ${p.id}: ${p.nombre} (activo: ${p.activo})`);
    });

    const productosListadosInactivos = await Producto.listar('', true);
    console.log(`  - Productos listados (incluyendo inactivos): ${productosListadosInactivos.length}`);
    productosListadosInactivos.forEach(p => {
      console.log(`    - ID ${p.id}: ${p.nombre} (activo: ${p.activo})`);
    });

    // 5. Verificar si hay algún problema con el tipo de dato
    console.log('\n🔍 Verificando tipos de datos...');
    const estructura = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'articulos' AND column_name = 'activo'
      ORDER BY ordinal_position
    `);
    
    estructura.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    // 6. Verificar valores exactos en la columna activo
    console.log('\n🔍 Verificando valores exactos en columna activo:');
    const valoresActivo = await pool.query('SELECT id, nombre, activo, pg_typeof(activo) as tipo FROM articulos ORDER BY id');
    valoresActivo.rows.forEach(p => {
      console.log(`  - ID ${p.id}: ${p.nombre} (activo: ${p.activo}, tipo: ${p.tipo})`);
    });

    console.log('\n🎉 Debug completado!');

  } catch (error) {
    console.error('❌ Error durante el debug:', error);
  } finally {
    await pool.end();
  }
}

debugStockFiltro();
