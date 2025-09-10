const pool = require('./config/database');

async function eliminarProductoConflicto() {
  try {
    console.log('🗑️ Eliminando producto con conflicto de código...\n');

    // Buscar producto con código "01"
    const productoConflicto = await pool.query(`
      SELECT id, nombre, codigo, activo, stock_minimo
      FROM articulos
      WHERE codigo = '01'
    `);

    if (productoConflicto.rows.length === 0) {
      console.log('✅ No hay productos con código "01"');
      return;
    }

    const producto = productoConflicto.rows[0];
    console.log(`📊 Producto encontrado:`);
    console.log(`  - ID: ${producto.id}`);
    console.log(`  - Nombre: ${producto.nombre}`);
    console.log(`  - Código: ${producto.codigo}`);
    console.log(`  - Activo: ${producto.activo}`);
    console.log(`  - Stock: ${producto.stock_minimo}`);

    // Eliminar movimientos de stock asociados
    await pool.query('DELETE FROM movimientos_stock WHERE articulo_id = $1', [producto.id]);
    console.log('  ✅ Movimientos de stock eliminados');

    // Eliminar detalles de ventas asociados
    await pool.query('DELETE FROM ventas_detalle WHERE producto_id = $1', [producto.id]);
    console.log('  ✅ Detalles de ventas eliminados');

    // Eliminar el producto
    await pool.query('DELETE FROM articulos WHERE id = $1', [producto.id]);
    console.log('  ✅ Producto eliminado completamente');

    // Verificar que se eliminó
    const verificacion = await pool.query(`
      SELECT COUNT(*) as total
      FROM articulos
      WHERE codigo = '01'
    `);

    if (verificacion.rows[0].total == 0) {
      console.log('\n✅ Producto eliminado exitosamente');
      console.log('💡 Ahora puedes crear productos sin conflictos de código');
    } else {
      console.log('\n❌ Error: El producto no se eliminó correctamente');
    }

    // Mostrar productos restantes
    console.log('\n📊 Productos restantes:');
    const productosRestantes = await pool.query(`
      SELECT id, nombre, codigo, activo
      FROM articulos
      ORDER BY id
    `);

    if (productosRestantes.rows.length === 0) {
      console.log('  - No hay productos registrados');
    } else {
      productosRestantes.rows.forEach(p => {
        console.log(`  - ${p.nombre} (Código: ${p.codigo || 'Sin código'})`);
      });
    }

  } catch (error) {
    console.error('❌ Error durante la eliminación:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar la eliminación
eliminarProductoConflicto();
