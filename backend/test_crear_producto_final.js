const pool = require('./config/database');

async function testCrearProductoFinal() {
  try {
    console.log('🧪 Probando creación de productos (versión final)...\n');

    // 1. Verificar estado inicial
    console.log('📊 Estado inicial:');
    const productosAntes = await pool.query('SELECT COUNT(*) as count FROM articulos');
    console.log(`  - Productos antes: ${productosAntes.rows[0].count}`);

    // 2. Probar creación sin categoría (como debería ser)
    console.log('\n🔍 Probando creación sin categoría...');
    const Articulo = require('./models/Articulo');
    
    try {
      const timestamp = Date.now();
      const productoTest = await Articulo.crear({
        nombre: `Producto Test ${timestamp}`,
        codigo: `TEST${timestamp}`,
        precio_compra: 1000,
        precio_venta: 2000,
        stock_minimo: 10,
        activo: true,
        iva: 10
      });
      console.log('  ✅ Producto creado sin categoría:', productoTest.nombre);
    } catch (error) {
      console.log('  ❌ Error creando producto sin categoría:', error.message);
    }

    // 3. Probar creación con datos del frontend (sin categoría)
    console.log('\n🔍 Probando creación con datos del frontend...');
    try {
      const timestamp = Date.now();
      const productoFrontend = await Articulo.crear({
        nombre: `Producto Frontend ${timestamp}`,
        codigo: `FRONT${timestamp}`,
        precio_compra: 3000,
        precio_venta: 6000,
        stock_minimo: 15,
        activo: true,
        iva: 10
      });
      console.log('  ✅ Producto creado con datos del frontend:', productoFrontend.nombre);
    } catch (error) {
      console.log('  ❌ Error creando producto con datos del frontend:', error.message);
    }

    // 4. Probar el controlador directamente
    console.log('\n🔍 Probando controlador directamente...');
    const ArticuloController = require('./controllers/articuloController');
    
    const timestamp = Date.now();
    const mockReq = {
      body: {
        nombre: `Producto Controlador ${timestamp}`,
        codigo: `CTRL${timestamp}`,
        precio_compra: 4000,
        precio_venta: 8000,
        stock_minimo: 25,
        activo: true,
        iva: 10
      }
    };
    
    const mockRes = {
      status: (code) => ({
        json: (data) => {
          if (code === 201) {
            console.log('  ✅ Controlador creó producto exitosamente:', data.data.nombre);
          } else {
            console.log(`  ❌ Controlador devuelve error ${code}:`, data);
          }
        }
      }),
      json: (data) => {
        console.log('  ✅ Controlador creó producto exitosamente:', data.data.nombre);
      }
    };

    // Probar el controlador
    await ArticuloController.crear(mockReq, mockRes);

    // 5. Verificar estado final
    console.log('\n📊 Estado final:');
    const productosDespues = await pool.query('SELECT COUNT(*) as count FROM articulos');
    console.log(`  - Productos después: ${productosDespues.rows[0].count}`);
    console.log(`  - Productos creados: ${productosDespues.rows[0].count - productosAntes.rows[0].count}`);

    // 6. Verificar productos creados recientemente
    console.log('\n🔍 Verificando productos creados recientemente...');
    const productosCreados = await pool.query(`
      SELECT id, nombre, codigo, precio_compra, precio_venta, stock_minimo, activo, iva, categoria_id
      FROM articulos 
      WHERE nombre LIKE '%Test%' OR nombre LIKE '%Frontend%' OR nombre LIKE '%Controlador%'
      ORDER BY id DESC 
      LIMIT 5
    `);
    
    productosCreados.rows.forEach((p, index) => {
      console.log(`  ${index + 1}. ${p.nombre} (ID: ${p.id})`);
      console.log(`     - Código: ${p.codigo}`);
      console.log(`     - Precio compra: ${p.precio_compra}`);
      console.log(`     - Precio venta: ${p.precio_venta}`);
      console.log(`     - Stock: ${p.stock_minimo}`);
      console.log(`     - Activo: ${p.activo}`);
      console.log(`     - IVA: ${p.iva}%`);
      console.log(`     - Categoría ID: ${p.categoria_id || 'NULL'}`);
    });

    console.log('\n🎉 Prueba completada exitosamente!');

  } catch (error) {
    console.error('❌ Error durante la prueba:', error);
  } finally {
    await pool.end();
  }
}

testCrearProductoFinal();
