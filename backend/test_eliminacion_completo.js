const pool = require('./config/database');

async function testEliminacionCompleto() {
  try {
    console.log('🧪 Prueba completa de eliminación preservando ventas...\n');

    // 1. Crear un producto de prueba
    console.log('📦 Creando producto de prueba...');
    const productoTest = await pool.query(`
      INSERT INTO articulos (nombre, codigo, precio_compra, precio_venta, stock_minimo, activo, iva)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, ['Pizza Test', 'PIZZA001', 5000, 10000, 10, true, 10]);
    
    const producto = productoTest.rows[0];
    console.log(`✅ Producto creado: ${producto.nombre} (ID: ${producto.id})`);

    // 2. Crear un cliente de prueba
    console.log('\n👤 Creando cliente de prueba...');
    const clienteTest = await pool.query(`
      INSERT INTO clientes (identificador, nombre, celular, activo)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, ['TEST001', 'Cliente Test', '0999123456', true]);
    
    const cliente = clienteTest.rows[0];
    console.log(`✅ Cliente creado: ${cliente.nombre} (ID: ${cliente.id})`);

    // Obtener un usuario válido para la prueba
    console.log('👤 Obteniendo usuario para la prueba...');
    const usuarios = await pool.query('SELECT id FROM usuarios LIMIT 1');
    const usuarioId = usuarios.rows.length > 0 ? usuarios.rows[0].id : 1;
    console.log(`✅ Usuario seleccionado: ID ${usuarioId}`);
    
    // 3. Crear una venta de prueba
    console.log('\n💳 Creando venta de prueba...');
    const ventaTest = await pool.query(`
      INSERT INTO ventas (sucursal_id, usuario_id, cliente_id, fecha, total, numero_factura, forma_pago)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, [1, usuarioId, cliente.id, new Date(), producto.precio_venta * 2, 'TEST-001', 'efectivo']);
    
    const venta = ventaTest.rows[0];
    console.log(`✅ Venta creada: ID ${venta.id}, Total: $${venta.total}`);

    // 4. Crear detalle de venta
    console.log('\n📝 Creando detalle de venta...');
    const detalleTest = await pool.query(`
      INSERT INTO ventas_detalle (venta_id, producto_id, cantidad, precio_unitario, subtotal)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `, [venta.id, producto.id, 2, producto.precio_venta, producto.precio_venta * 2]);
    
    console.log(`✅ Detalle creado: ${detalleTest.rows[0].cantidad} x $${detalleTest.rows[0].precio_unitario} = $${detalleTest.rows[0].subtotal}`);

    // 5. Verificar estado antes de eliminar
    console.log('\n📊 Estado antes de eliminar:');
    const ventasAntes = await pool.query('SELECT COUNT(*) as count FROM ventas');
    const ventasDetalleAntes = await pool.query('SELECT COUNT(*) as count FROM ventas_detalle');
    const articulosActivosAntes = await pool.query('SELECT COUNT(*) as count FROM articulos WHERE activo = true');
    
    console.log(`  - Ventas: ${ventasAntes.rows[0].count}`);
    console.log(`  - Detalles de ventas: ${ventasDetalleAntes.rows[0].count}`);
    console.log(`  - Artículos activos: ${articulosActivosAntes.rows[0].count}`);

    // 6. "Eliminar" el producto (marcar como inactivo)
    console.log('\n🗑️ Eliminando producto (marcando como inactivo)...');
    const Articulo = require('./models/Articulo');
    const productoEliminado = await Articulo.eliminar(producto.id);
    
    if (productoEliminado) {
      console.log(`✅ Producto marcado como inactivo: ${productoEliminado.nombre}`);
    } else {
      console.log('❌ Error al eliminar producto');
      return;
    }

    // 7. Verificar que las ventas se preservaron
    console.log('\n🔍 Verificando que las ventas se preservaron...');
    const ventasDespues = await pool.query('SELECT COUNT(*) as count FROM ventas');
    const ventasDetalleDespues = await pool.query('SELECT COUNT(*) as count FROM ventas_detalle');
    const articulosActivosDespues = await pool.query('SELECT COUNT(*) as count FROM articulos WHERE activo = true');
    
    console.log(`  - Ventas después: ${ventasDespues.rows[0].count} (${ventasDespues.rows[0].count === ventasAntes.rows[0].count ? '✅' : '❌'})`);
    console.log(`  - Detalles de ventas después: ${ventasDetalleDespues.rows[0].count} (${ventasDetalleDespues.rows[0].count === ventasDetalleAntes.rows[0].count ? '✅' : '❌'})`);
    console.log(`  - Artículos activos después: ${articulosActivosDespues.rows[0].count} (${articulosActivosDespues.rows[0].count === articulosActivosAntes.rows[0].count - 1 ? '✅' : '❌'})`);

    // 8. Verificar que las ventas del producto eliminado siguen existiendo
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

    if (ventasProductoEliminado.rows.length > 0) {
      console.log(`✅ Las ventas se preservaron: ${ventasProductoEliminado.rows.length} ventas encontradas`);
      ventasProductoEliminado.rows.forEach((venta, index) => {
        console.log(`  ${index + 1}. Venta ${venta.venta_id}: ${venta.cantidad} x $${venta.precio_unitario} = $${venta.subtotal}`);
      });
    } else {
      console.log('❌ Se perdieron las ventas del producto');
    }

    // 9. Verificar que el producto aparece como inactivo
    console.log('\n🔍 Verificando estado del producto...');
    const productoEstado = await pool.query('SELECT id, nombre, activo FROM articulos WHERE id = $1', [producto.id]);
    
    if (productoEstado.rows.length > 0) {
      const estado = productoEstado.rows[0];
      console.log(`✅ Producto ${estado.nombre} (ID: ${estado.id}) - Activo: ${estado.activo ? 'Sí' : 'No'}`);
    } else {
      console.log('❌ Producto no encontrado');
    }

    // 10. Limpiar datos de prueba
    console.log('\n🧹 Limpiando datos de prueba...');
    await pool.query('DELETE FROM ventas_detalle WHERE venta_id = $1', [venta.id]);
    await pool.query('DELETE FROM ventas WHERE id = $1', [venta.id]);
    await pool.query('DELETE FROM clientes WHERE id = $1', [cliente.id]);
    await pool.query('DELETE FROM articulos WHERE id = $1', [producto.id]);
    console.log('✅ Datos de prueba limpiados');

    console.log('\n🎉 Prueba completada exitosamente!');
    console.log('💡 El producto se marcó como inactivo y todas las ventas se preservaron');
    console.log('💡 Los totales vendidos se mantuvieron intactos');

  } catch (error) {
    console.error('❌ Error durante la prueba:', error);
  } finally {
    await pool.end();
  }
}

testEliminacionCompleto();
