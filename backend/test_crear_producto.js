const pool = require('./config/database');

async function testCrearProducto() {
  try {
    console.log('🧪 Probando creación de productos...\n');

    // 1. Verificar estado inicial
    console.log('📊 Estado inicial:');
    const productosAntes = await pool.query('SELECT COUNT(*) as count FROM articulos');
    console.log(`  - Productos antes: ${productosAntes.rows[0].count}`);

    // 2. Probar creación con datos mínimos
    console.log('\n🔍 Probando creación con datos mínimos...');
    const Articulo = require('./models/Articulo');
    
    try {
      const productoMinimo = await Articulo.crear({
        nombre: 'Producto Test Mínimo',
        codigo: 'TEST001',
        precio_compra: 1000,
        precio_venta: 2000,
        stock_minimo: 10,
        activo: true,
        iva: 10
      });
      console.log('  ✅ Producto creado con datos mínimos:', productoMinimo.nombre);
    } catch (error) {
      console.log('  ❌ Error creando producto con datos mínimos:', error.message);
    }

    // 3. Probar creación con datos completos
    console.log('\n🔍 Probando creación con datos completos...');
    try {
      const productoCompleto = await Articulo.crear({
        nombre: 'Producto Test Completo',
        codigo: 'TEST002',
        categoria_id: 1,
        precio_compra: 5000,
        precio_venta: 10000,
        stock_minimo: 20,
        activo: true,
        iva: 10
      });
      console.log('  ✅ Producto creado con datos completos:', productoCompleto.nombre);
    } catch (error) {
      console.log('  ❌ Error creando producto con datos completos:', error.message);
    }

    // 4. Probar creación con datos del frontend
    console.log('\n🔍 Probando creación con datos del frontend...');
    try {
      const productoFrontend = await Articulo.crear({
        nombre: 'Producto Frontend Test',
        codigo: 'FRONT001',
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

    // 5. Verificar estado final
    console.log('\n📊 Estado final:');
    const productosDespues = await pool.query('SELECT COUNT(*) as count FROM articulos');
    console.log(`  - Productos después: ${productosDespues.rows[0].count}`);
    console.log(`  - Productos creados: ${productosDespues.rows[0].count - productosAntes.rows[0].count}`);

    // 6. Verificar productos creados
    console.log('\n🔍 Verificando productos creados...');
    const productosCreados = await pool.query(`
      SELECT id, nombre, codigo, precio_compra, precio_venta, stock_minimo, activo, iva 
      FROM articulos 
      WHERE nombre LIKE '%Test%' 
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
    });

    // 7. Probar el controlador directamente
    console.log('\n🔍 Probando controlador directamente...');
    const ArticuloController = require('./controllers/articuloController');
    
    // Simular request y response
    const mockReq = {
      body: {
        nombre: 'Producto Controlador Test',
        codigo: 'CTRL001',
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

    console.log('\n🎉 Prueba completada exitosamente!');

  } catch (error) {
    console.error('❌ Error durante la prueba:', error);
  } finally {
    await pool.end();
  }
}

testCrearProducto();
