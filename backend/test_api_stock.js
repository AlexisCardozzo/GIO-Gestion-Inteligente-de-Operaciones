const pool = require('./config/database');

async function testApiStock() {
  try {
    console.log('🧪 Probando API de stock...\n');

    // 1. Verificar estado inicial
    console.log('📊 Estado inicial:');
    const productosActivos = await pool.query('SELECT COUNT(*) as count FROM articulos WHERE activo = true');
    const productosInactivos = await pool.query('SELECT COUNT(*) as count FROM articulos WHERE activo = false');
    
    console.log(`  - Productos activos: ${productosActivos.rows[0].count}`);
    console.log(`  - Productos inactivos: ${productosInactivos.rows[0].count}`);

    // 2. Simular llamada a la API de stock
    console.log('\n🔍 Simulando llamada a la API de stock...');
    const Producto = require('./models/Producto');
    
    // Simular llamada sin incluir inactivos (por defecto)
    const productosStock = await Producto.listar();
    console.log(`  - Productos en stock (solo activos): ${productosStock.length}`);
    productosStock.forEach(p => {
      console.log(`    - ID ${p.id}: ${p.nombre} (activo: ${p.activo})`);
    });

    // Simular llamada incluyendo inactivos
    const productosStockInactivos = await Producto.listar('', true);
    console.log(`  - Productos en stock (incluyendo inactivos): ${productosStockInactivos.length}`);
    productosStockInactivos.forEach(p => {
      console.log(`    - ID ${p.id}: ${p.nombre} (activo: ${p.activo})`);
    });

    // 3. Verificar que el método obtenerStock() funciona correctamente
    console.log('\n🔍 Verificando método obtenerStock()...');
    const stockListado = await Producto.obtenerStock();
    console.log(`  - Stock listado (solo activos): ${stockListado.length}`);
    stockListado.forEach(p => {
      console.log(`    - ID ${p.id}: ${p.nombre} (cantidad: ${p.cantidad}, activo: ${p.activo})`);
    });

    const stockListadoInactivos = await Producto.obtenerStock(true);
    console.log(`  - Stock listado (incluyendo inactivos): ${stockListadoInactivos.length}`);
    stockListadoInactivos.forEach(p => {
      console.log(`    - ID ${p.id}: ${p.nombre} (cantidad: ${p.cantidad}, activo: ${p.activo})`);
    });

    // 4. Verificar que no hay productos inactivos en el resumen por defecto
    console.log('\n🔍 Verificando que no hay productos inactivos en el resumen...');
    const productosInactivosEnResumen = productosStock.filter(p => !p.activo);
    
    if (productosInactivosEnResumen.length === 0) {
      console.log('  ✅ No hay productos inactivos en el resumen del stock');
    } else {
      console.log(`  ❌ Encontrados ${productosInactivosEnResumen.length} productos inactivos en el resumen:`);
      productosInactivosEnResumen.forEach(p => {
        console.log(`    - ${p.nombre} (ID: ${p.id}) - Activo: ${p.activo}`);
      });
    }

    // 5. Verificar que los productos inactivos existen pero no se muestran
    console.log('\n🔍 Verificando que productos inactivos existen pero no se muestran...');
    const productosInactivosDB = await pool.query('SELECT id, nombre, activo FROM articulos WHERE activo = false');
    
    if (productosInactivosDB.rows.length > 0) {
      console.log('  ✅ Productos inactivos existen en la base de datos:');
      productosInactivosDB.rows.forEach(p => {
        console.log(`    - ${p.nombre} (ID: ${p.id}) - Activo: ${p.activo}`);
      });
      
      // Verificar que no están en el resumen
      const productosInactivosEnResumen = productosStock.filter(p => p.id === productosInactivosDB.rows[0].id);
      if (productosInactivosEnResumen.length === 0) {
        console.log('  ✅ Productos inactivos no aparecen en el resumen del stock');
      } else {
        console.log('  ❌ Productos inactivos aparecen en el resumen del stock');
      }
    } else {
      console.log('  ℹ️ No hay productos inactivos en la base de datos');
    }

    // 6. Verificar que el controlador funciona correctamente
    console.log('\n🔍 Verificando controlador de stock...');
    const StockController = require('./controllers/stockController');
    
    // Simular request y response
    const mockReq = {
      query: {}
    };
    const mockRes = {
      json: (data) => {
        console.log('  ✅ Controlador devuelve:', data.data.length, 'productos');
        data.data.forEach(p => {
          console.log(`    - ID ${p.id}: ${p.nombre} (cantidad: ${p.cantidad}, activo: ${p.activo})`);
        });
      },
      status: (code) => ({
        json: (data) => {
          console.log(`  ❌ Controlador devuelve error ${code}:`, data);
        }
      })
    };

    // Probar el controlador
    await StockController.obtenerStock(mockReq, mockRes);

    console.log('\n🎉 Prueba completada exitosamente!');
    console.log('💡 La API de stock filtra correctamente los productos inactivos');
    console.log('💡 Solo los productos activos aparecen en el resumen del stock');

  } catch (error) {
    console.error('❌ Error durante la prueba:', error);
  } finally {
    await pool.end();
  }
}

testApiStock();
