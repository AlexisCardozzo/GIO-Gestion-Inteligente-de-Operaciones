const pool = require('./config/database');

async function verificacionFinalConteo() {
  try {
    console.log('🎯 Verificación final del conteo de ventas...\n');

    // 1. Verificar ventas reales
    console.log('📊 Ventas reales en la base de datos:');
    
    const ventasReales = await pool.query(`
      SELECT COUNT(*) as total_ventas
      FROM ventas
    `);
    
    const totalVentas = ventasReales.rows[0].total_ventas;
    console.log(`  - Total ventas: ${totalVentas}`);

    // 2. Verificar movimientos con venta_id
    console.log('\n📈 Movimientos con venta_id:');
    
    const movimientosConVentaId = await pool.query(`
      SELECT COUNT(*) as total_movimientos
      FROM movimientos_stock
      WHERE referencia LIKE 'venta_id=%'
    `);
    
    const totalMovimientos = movimientosConVentaId.rows[0].total_movimientos;
    console.log(`  - Total movimientos: ${totalMovimientos}`);

    // 3. Contar ventas únicas por venta_id
    const ventaIds = new Set();
    const todosMovimientos = await pool.query(`
      SELECT referencia
      FROM movimientos_stock
      WHERE referencia LIKE 'venta_id=%'
    `);
    
    todosMovimientos.rows.forEach(mov => {
      const ventaIdMatch = mov.referencia.match(/venta_id=(\d+)/);
      if (ventaIdMatch) {
        ventaIds.add(ventaIdMatch[1]);
      }
    });
    
    console.log(`  - Ventas únicas por venta_id: ${ventaIds.size}`);

    // 4. Verificar últimas ventas
    console.log('\n🛒 Últimas 5 ventas:');
    
    const ultimasVentas = await pool.query(`
      SELECT id, fecha, total, forma_pago
      FROM ventas
      ORDER BY fecha DESC
      LIMIT 5
    `);
    
    ultimasVentas.rows.forEach(venta => {
      console.log(`  - Venta ${venta.id}: $${venta.total} (${venta.forma_pago}) - ${venta.fecha}`);
    });

    // 5. Verificar últimos movimientos
    console.log('\n📦 Últimos 5 movimientos:');
    
    const ultimosMovimientos = await pool.query(`
      SELECT ms.id, ms.referencia, ms.fecha_hora, a.nombre as producto
      FROM movimientos_stock ms
      LEFT JOIN articulos a ON ms.articulo_id = a.id
      WHERE ms.referencia LIKE 'venta_id=%'
      ORDER BY ms.fecha_hora DESC
      LIMIT 5
    `);
    
    ultimosMovimientos.rows.forEach(mov => {
      console.log(`  - Movimiento ${mov.id}: ${mov.producto} - ${mov.referencia} - ${mov.fecha_hora}`);
    });

    // 6. Comparación final
    console.log('\n📊 Comparación final:');
    console.log(`  - Ventas reales en BD: ${totalVentas}`);
    console.log(`  - Ventas únicas por venta_id: ${ventaIds.size}`);
    
    const diferencia = totalVentas - ventaIds.size;
    if (diferencia == 0) {
      console.log(`  ✅ Los conteos coinciden perfectamente!`);
    } else {
      console.log(`  ⚠️ Diferencia: ${diferencia} ventas`);
      console.log(`  💡 Esto significa que el frontend ahora debería mostrar ${ventaIds.size} ventas`);
    }

    console.log('\n🎉 Verificación completada!');
    console.log('💡 El frontend ahora debería mostrar el conteo correcto de ventas');

  } catch (error) {
    console.error('❌ Error en verificación:', error);
  } finally {
    await pool.end();
  }
}

verificacionFinalConteo(); 