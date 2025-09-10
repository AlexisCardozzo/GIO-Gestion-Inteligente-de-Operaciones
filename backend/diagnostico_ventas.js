const pool = require('./config/database');

async function diagnosticoVentas() {
  try {
    console.log('🔍 Iniciando diagnóstico del flujo de ventas...\n');

    // 1. Verificar últimas ventas registradas
    console.log('📊 Últimas 5 ventas registradas:');
    const ultimasVentas = await pool.query(`
      SELECT 
        v.id,
        v.fecha,
        v.total,
        v.forma_pago,
        v.numero_factura,
        c.nombre as cliente_nombre,
        c.identificador as cliente_ci
      FROM ventas v
      LEFT JOIN clientes c ON v.cliente_id = c.id
      ORDER BY v.fecha DESC
      LIMIT 5
    `);
    
    ultimasVentas.rows.forEach(venta => {
      console.log(`  - ID: ${venta.id}, Cliente: ${venta.cliente_nombre} (${venta.cliente_ci}), Total: $${venta.total}, Método: ${venta.forma_pago}, Fecha: ${venta.fecha}`);
    });

    // 2. Verificar detalles de ventas
    console.log('\n📋 Detalles de ventas:');
    const detallesVentas = await pool.query(`
      SELECT 
        vd.venta_id,
        vd.producto_id,
        vd.cantidad,
        vd.precio_unitario,
        vd.subtotal,
        a.nombre as producto_nombre
      FROM ventas_detalle vd
      LEFT JOIN articulos a ON vd.producto_id = a.id
      ORDER BY vd.venta_id DESC
      LIMIT 10
    `);
    
    detallesVentas.rows.forEach(detalle => {
      console.log(`  - Venta ${detalle.venta_id}: ${detalle.producto_nombre} x${detalle.cantidad} = $${detalle.subtotal}`);
    });

    // 3. Verificar fidelización
    console.log('\n🎯 Estado de fidelización:');
    const fidelizacion = await pool.query(`
      SELECT 
        fc.cliente_id,
        c.nombre as cliente_nombre,
        fc.puntos_acumulados,
        fc.ultima_actualizacion,
        fc.campania_id
      FROM fidelizacion_clientes fc
      LEFT JOIN clientes c ON fc.cliente_id = c.id
      ORDER BY fc.ultima_actualizacion DESC
      LIMIT 5
    `);
    
    if (fidelizacion.rows.length > 0) {
      fidelizacion.rows.forEach(fc => {
        console.log(`  - Cliente ${fc.cliente_nombre}: ${fc.puntos_acumulados} puntos (campaña ${fc.campania_id})`);
      });
    } else {
      console.log('  - No hay datos de fidelización');
    }

    // 4. Verificar campañas activas
    console.log('\n🏆 Campañas activas:');
    const campanias = await pool.query(`
      SELECT id, nombre, descripcion, activa, tipo_campania
      FROM fidelizacion_campanias
      WHERE activa = true
    `);
    
    campanias.rows.forEach(campania => {
      console.log(`  - ${campania.nombre}: ${campania.descripcion} (${campania.tipo_campania})`);
    });

    // 5. Verificar errores en logs (simulado)
    console.log('\n⚠️ Posibles problemas identificados:');
    
    // Verificar ventas sin detalles
    const ventasSinDetalles = await pool.query(`
      SELECT v.id, v.fecha, v.total
      FROM ventas v
      LEFT JOIN ventas_detalle vd ON v.id = vd.venta_id
      WHERE vd.venta_id IS NULL
    `);
    
    if (ventasSinDetalles.rows.length > 0) {
      console.log('  ❌ Ventas sin detalles de productos:');
      ventasSinDetalles.rows.forEach(venta => {
        console.log(`    - Venta ID ${venta.id} (${venta.fecha}): $${venta.total}`);
      });
    } else {
      console.log('  ✅ Todas las ventas tienen detalles');
    }

    // Verificar clientes sin fidelización
    const clientesSinFidelizacion = await pool.query(`
      SELECT c.id, c.nombre, c.identificador
      FROM clientes c
      LEFT JOIN fidelizacion_clientes fc ON c.id = fc.cliente_id
      WHERE fc.cliente_id IS NULL
      AND c.activo = true
    `);
    
    if (clientesSinFidelizacion.rows.length > 0) {
      console.log('  ⚠️ Clientes sin registro de fidelización:');
      clientesSinFidelizacion.rows.forEach(cliente => {
        console.log(`    - ${cliente.nombre} (${cliente.identificador})`);
      });
    } else {
      console.log('  ✅ Todos los clientes tienen fidelización');
    }

    // 6. Verificar integridad de datos
    console.log('\n🔒 Verificación de integridad:');
    
    // Verificar que los totales coincidan
    const totalesInconsistentes = await pool.query(`
      SELECT 
        v.id,
        v.total as total_venta,
        SUM(vd.subtotal) as total_detalles
      FROM ventas v
      LEFT JOIN ventas_detalle vd ON v.id = vd.venta_id
      GROUP BY v.id, v.total
      HAVING ABS(v.total - COALESCE(SUM(vd.subtotal), 0)) > 0.01
    `);
    
    if (totalesInconsistentes.rows.length > 0) {
      console.log('  ❌ Inconsistencias en totales:');
      totalesInconsistentes.rows.forEach(inconsistencia => {
        console.log(`    - Venta ${inconsistencia.id}: Venta=${inconsistencia.total_venta}, Detalles=${inconsistencia.total_detalles}`);
      });
    } else {
      console.log('  ✅ Todos los totales son consistentes');
    }

    console.log('\n🎉 Diagnóstico completado!');
    console.log('💡 Si hay errores, revisa los logs del servidor para más detalles');

  } catch (error) {
    console.error('❌ Error en diagnóstico:', error);
  } finally {
    await pool.end();
  }
}

diagnosticoVentas(); 