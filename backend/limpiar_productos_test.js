const pool = require('./config/database');

async function limpiarProductosTest() {
  try {
    console.log('🧹 Limpiando productos de prueba...\n');

    // 1. Identificar productos de prueba
    console.log('📊 Productos de prueba encontrados:');
    const productosTest = await pool.query(`
      SELECT id, nombre, activo, stock_minimo
      FROM articulos
      WHERE nombre LIKE '%Test%' OR nombre LIKE '%Frontend%' OR nombre LIKE '%Controlador%'
      ORDER BY id
    `);

    if (productosTest.rows.length === 0) {
      console.log('✅ No hay productos de prueba para eliminar');
      return;
    }

    productosTest.rows.forEach(producto => {
      console.log(`  - ${producto.nombre} (ID: ${producto.id}) - Activo: ${producto.activo}`);
    });

    // 2. Eliminar completamente los productos de prueba
    console.log('\n🗑️ Eliminando productos de prueba...');
    for (const producto of productosTest.rows) {
      // Eliminar movimientos de stock asociados
      await pool.query('DELETE FROM movimientos_stock WHERE articulo_id = $1', [producto.id]);
      console.log(`  ✅ Movimientos eliminados para ${producto.nombre}`);

      // Eliminar detalles de ventas asociados
      await pool.query('DELETE FROM ventas_detalle WHERE producto_id = $1', [producto.id]);
      console.log(`  ✅ Detalles de ventas eliminados para ${producto.nombre}`);

      // Eliminar el producto completamente
      await pool.query('DELETE FROM articulos WHERE id = $1', [producto.id]);
      console.log(`  ✅ Producto ${producto.nombre} eliminado completamente`);
    }

    // 3. Verificar que solo queden productos reales
    console.log('\n📊 Productos restantes:');
    const productosRestantes = await pool.query(`
      SELECT id, nombre, activo, stock_minimo
      FROM articulos
      ORDER BY id
    `);

    productosRestantes.rows.forEach(producto => {
      console.log(`  - ${producto.nombre} (ID: ${producto.id}) - Activo: ${producto.activo}`);
    });

    // 4. Resumen final
    console.log('\n📈 Resumen final:');
    const totalProductos = await pool.query('SELECT COUNT(*) as total FROM articulos');
    const totalMovimientos = await pool.query('SELECT COUNT(*) as total FROM movimientos_stock');
    const totalDetalles = await pool.query('SELECT COUNT(*) as total FROM ventas_detalle');
    
    console.log(`  - Productos restantes: ${totalProductos.rows[0].total}`);
    console.log(`  - Movimientos de stock: ${totalMovimientos.rows[0].total}`);
    console.log(`  - Detalles de ventas: ${totalDetalles.rows[0].total}`);

    console.log('\n🎉 Limpieza de productos de prueba completada!');
    console.log('💡 Solo quedan productos reales en el sistema');

  } catch (error) {
    console.error('❌ Error durante la limpieza:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar la limpieza
limpiarProductosTest();
