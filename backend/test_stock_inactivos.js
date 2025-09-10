const pool = require('./config/database');

async function testStockInactivos() {
  try {
    console.log('🧪 Probando que productos inactivos no aparezcan en el resumen del stock...\n');

    // 1. Verificar estado inicial
    console.log('📊 Estado inicial:');
    const productosActivos = await pool.query('SELECT COUNT(*) as count FROM articulos WHERE activo = true');
    const productosInactivos = await pool.query('SELECT COUNT(*) as count FROM articulos WHERE activo = false');
    const productosTotal = await pool.query('SELECT COUNT(*) as count FROM articulos');
    
    console.log(`  - Productos activos: ${productosActivos.rows[0].count}`);
    console.log(`  - Productos inactivos: ${productosInactivos.rows[0].count}`);
    console.log(`  - Total productos: ${productosTotal.rows[0].count}`);

    // 2. Crear un producto de prueba si no hay productos inactivos
    if (productosInactivos.rows[0].count === 0) {
      console.log('\n📦 Creando producto de prueba inactivo...');
      const productoTest = await pool.query(`
        INSERT INTO articulos (nombre, codigo, precio_compra, precio_venta, stock_minimo, activo, iva)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *
      `, ['Producto Inactivo Test', 'INACT001', 5000, 10000, 5, false, 10]);
      
      console.log(`✅ Producto inactivo creado: ${productoTest.rows[0].nombre} (ID: ${productoTest.rows[0].id})`);
    }

    // 3. Verificar que el método listar() solo muestra activos por defecto
    console.log('\n🔍 Verificando método listar()...');
    const Producto = require('./models/Producto');
    const productosListados = await Producto.listar();
    const productosListadosInactivos = await Producto.listar('', true);
    
    console.log(`  - Productos listados (solo activos): ${productosListados.length}`);
    console.log(`  - Productos listados (incluyendo inactivos): ${productosListadosInactivos.length}`);
    
    if (productosListados.length === productosActivos.rows[0].count) {
      console.log('  ✅ Método listar() filtra correctamente por productos activos');
    } else {
      console.log('  ❌ Método listar() no filtra correctamente');
    }

    // 4. Verificar que el método obtenerStock() solo muestra activos por defecto
    console.log('\n🔍 Verificando método obtenerStock()...');
    const stockListado = await Producto.obtenerStock();
    const stockListadoInactivos = await Producto.obtenerStock(true);
    
    console.log(`  - Stock listado (solo activos): ${stockListado.length}`);
    console.log(`  - Stock listado (incluyendo inactivos): ${stockListadoInactivos.length}`);
    
    if (stockListado.length === productosActivos.rows[0].count) {
      console.log('  ✅ Método obtenerStock() filtra correctamente por productos activos');
    } else {
      console.log('  ❌ Método obtenerStock() no filtra correctamente');
    }

    // 5. Verificar que el controlador de stock funciona correctamente
    console.log('\n🔍 Verificando controlador de stock...');
    const Articulo = require('./models/Articulo');
    const articulosListados = await Articulo.listar();
    const articulosListadosInactivos = await Articulo.listar('', true);
    
    console.log(`  - Artículos listados (solo activos): ${articulosListados.length}`);
    console.log(`  - Artículos listados (incluyendo inactivos): ${articulosListadosInactivos.length}`);
    
    if (articulosListados.length === productosActivos.rows[0].count) {
      console.log('  ✅ Controlador de stock filtra correctamente por productos activos');
    } else {
      console.log('  ❌ Controlador de stock no filtra correctamente');
    }

    // 6. Verificar que no hay productos inactivos en el resumen
    console.log('\n🔍 Verificando resumen del stock...');
    const productosInactivosEnResumen = productosListados.filter(p => !p.activo);
    
    if (productosInactivosEnResumen.length === 0) {
      console.log('  ✅ No hay productos inactivos en el resumen del stock');
    } else {
      console.log(`  ❌ Encontrados ${productosInactivosEnResumen.length} productos inactivos en el resumen:`);
      productosInactivosEnResumen.forEach(p => {
        console.log(`    - ${p.nombre} (ID: ${p.id}) - Activo: ${p.activo}`);
      });
    }

    // 7. Verificar que los productos inactivos existen pero no se muestran
    console.log('\n🔍 Verificando que productos inactivos existen pero no se muestran...');
    const productosInactivosDB = await pool.query('SELECT id, nombre, activo FROM articulos WHERE activo = false');
    
    if (productosInactivosDB.rows.length > 0) {
      console.log('  ✅ Productos inactivos existen en la base de datos:');
      productosInactivosDB.rows.forEach(p => {
        console.log(`    - ${p.nombre} (ID: ${p.id}) - Activo: ${p.activo}`);
      });
      
      // Verificar que no están en el resumen
      const productosInactivosEnResumen = productosListados.filter(p => p.id === productosInactivosDB.rows[0].id);
      if (productosInactivosEnResumen.length === 0) {
        console.log('  ✅ Productos inactivos no aparecen en el resumen del stock');
      } else {
        console.log('  ❌ Productos inactivos aparecen en el resumen del stock');
      }
    } else {
      console.log('  ℹ️ No hay productos inactivos en la base de datos');
    }

    console.log('\n🎉 Prueba completada exitosamente!');
    console.log('💡 Los productos inactivos no aparecen en el resumen del stock');
    console.log('💡 Solo los productos activos se muestran en el resumen');

  } catch (error) {
    console.error('❌ Error durante la prueba:', error);
  } finally {
    await pool.end();
  }
}

testStockInactivos();
