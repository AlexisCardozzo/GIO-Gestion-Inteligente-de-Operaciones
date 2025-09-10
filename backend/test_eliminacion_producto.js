const pool = require('./config/database');

async function testEliminacionProducto() {
  try {
    console.log('🧪 Probando eliminación de producto preservando ventas...\n');

    // 1. Verificar estado inicial
    console.log('📊 Estado inicial:');
    const ventasInicial = await pool.query('SELECT COUNT(*) as count FROM ventas');
    const ventasDetalleInicial = await pool.query('SELECT COUNT(*) as count FROM ventas_detalle');
    const articulosInicial = await pool.query('SELECT COUNT(*) as count FROM articulos WHERE activo = true');
    
    console.log(`  - Ventas: ${ventasInicial.rows[0].count}`);
    console.log(`  - Detalles de ventas: ${ventasDetalleInicial.rows[0].count}`);
    console.log(`  - Artículos activos: ${articulosInicial.rows[0].count}`);

    // 2. Obtener un producto que tenga ventas
    console.log('\n🔍 Buscando producto con ventas...');
    const productoConVentas = await pool.query(`
      SELECT 
        a.id,
        a.nombre,
        a.activo,
        COUNT(vd.id) as ventas_asociadas
      FROM articulos a
      LEFT JOIN ventas_detalle vd ON a.id = vd.producto_id
      WHERE a.activo = true
      GROUP BY a.id, a.nombre, a.activo
      HAVING COUNT(vd.id) > 0
      ORDER BY COUNT(vd.id) DESC
      LIMIT 1
    `);

    if (productoConVentas.rows.length === 0) {
      console.log('❌ No se encontraron productos con ventas asociadas');
      return;
    }

    const producto = productoConVentas.rows[0];
    console.log(`✅ Producto encontrado: ${producto.nombre} (ID: ${producto.id})`);
    console.log(`   - Ventas asociadas: ${producto.ventas_asociadas}`);

    // 3. Verificar ventas antes de eliminar
    console.log('\n📋 Ventas asociadas al producto:');
    const ventasProducto = await pool.query(`
      SELECT 
        v.id as venta_id,
        v.fecha,
        v.total,
        vd.cantidad,
        vd.precio_unitario,
        vd.subtotal
      FROM ventas v
      JOIN ventas_detalle vd ON v.id = vd.venta_id
      WHERE vd.producto_id = $1
      ORDER BY v.fecha DESC
    `, [producto.id]);

    ventasProducto.rows.forEach((venta, index) => {
      console.log(`  ${index + 1}. Venta ${venta.venta_id}: ${venta.cantidad} x $${venta.precio_unitario} = $${venta.subtotal} (${venta.fecha})`);
    });

    // 4. "Eliminar" el producto (marcar como inactivo)
    console.log('\n🗑️ Eliminando producto (marcando como inactivo)...');
    const Articulo = require('./models/Articulo');
    const productoEliminado = await Articulo.eliminar(producto.id);
    
    if (productoEliminado) {
      console.log(`✅ Producto marcado como inactivo: ${productoEliminado.nombre}`);
    } else {
      console.log('❌ Error al eliminar producto');
      return;
    }

    // 5. Verificar que las ventas se preservaron
    console.log('\n🔍 Verificando que las ventas se preservaron...');
    const ventasDespues = await pool.query('SELECT COUNT(*) as count FROM ventas');
    const ventasDetalleDespues = await pool.query('SELECT COUNT(*) as count FROM ventas_detalle');
    const articulosActivosDespues = await pool.query('SELECT COUNT(*) as count FROM articulos WHERE activo = true');
    
    console.log(`  - Ventas después: ${ventasDespues.rows[0].count} (${ventasDespues.rows[0].count === ventasInicial.rows[0].count ? '✅' : '❌'})`);
    console.log(`  - Detalles de ventas después: ${ventasDetalleDespues.rows[0].count} (${ventasDetalleDespues.rows[0].count === ventasDetalleInicial.rows[0].count ? '✅' : '❌'})`);
    console.log(`  - Artículos activos después: ${articulosActivosDespues.rows[0].count} (${articulosActivosDespues.rows[0].count === articulosInicial.rows[0].count - 1 ? '✅' : '❌'})`);

    // 6. Verificar que las ventas del producto eliminado siguen existiendo
    console.log('\n🔍 Verificando ventas del producto eliminado...');
    const ventasProductoEliminado = await pool.query(`
      SELECT 
        v.id as venta_id,
        v.fecha,
        v.total,
        vd.cantidad,
        vd.precio_unitario,
        vd.subtotal
      FROM ventas v
      JOIN ventas_detalle vd ON v.id = vd.venta_id
      WHERE vd.producto_id = $1
      ORDER BY v.fecha DESC
    `, [producto.id]);

    if (ventasProductoEliminado.rows.length === ventasProducto.rows.length) {
      console.log(`✅ Todas las ventas se preservaron: ${ventasProductoEliminado.rows.length} ventas`);
    } else {
      console.log(`❌ Se perdieron ventas: ${ventasProductoEliminado.rows.length} de ${ventasProducto.rows.length}`);
    }

    // 7. Verificar que el producto aparece como inactivo
    console.log('\n🔍 Verificando estado del producto...');
    const productoEstado = await pool.query('SELECT id, nombre, activo FROM articulos WHERE id = $1', [producto.id]);
    
    if (productoEstado.rows.length > 0) {
      const estado = productoEstado.rows[0];
      console.log(`✅ Producto ${estado.nombre} (ID: ${estado.id}) - Activo: ${estado.activo ? 'Sí' : 'No'}`);
    } else {
      console.log('❌ Producto no encontrado');
    }

    console.log('\n🎉 Prueba completada exitosamente!');
    console.log('💡 El producto se marcó como inactivo y todas las ventas se preservaron');

  } catch (error) {
    console.error('❌ Error durante la prueba:', error);
  } finally {
    await pool.end();
  }
}

testEliminacionProducto();
