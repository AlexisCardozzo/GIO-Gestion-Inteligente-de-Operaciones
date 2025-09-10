const pool = require('./config/database');

async function verificacionFinalCompleta() {
  try {
    console.log('🎯 Verificación final completa del sistema de ventas...\n');

    // 1. Verificar ventas totales
    console.log('📊 Estado actual de ventas:');
    
    const totalVentas = await pool.query(`
      SELECT COUNT(*) as total
      FROM ventas
    `);
    
    console.log(`  - Total ventas en BD: ${totalVentas.rows[0].total}`);

    // 2. Verificar movimientos con venta_id
    const movimientosConVentaId = await pool.query(`
      SELECT COUNT(*) as total
      FROM movimientos_stock
      WHERE referencia LIKE 'venta_id=%'
    `);
    
    console.log(`  - Total movimientos con venta_id: ${movimientosConVentaId.rows[0].total}`);

    // 3. Contar ventas únicas
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
    
    console.log(`  - Ventas únicas contadas: ${ventaIds.size}`);

    // 4. Verificar últimas ventas registradas
    console.log('\n🛒 Últimas 5 ventas registradas:');
    
    const ultimasVentas = await pool.query(`
      SELECT id, fecha, total, forma_pago
      FROM ventas
      ORDER BY fecha DESC
      LIMIT 5
    `);
    
    ultimasVentas.rows.forEach(venta => {
      console.log(`  - Venta ${venta.id}: $${venta.total} (${venta.forma_pago}) - ${venta.fecha}`);
    });

    // 5. Verificar movimientos correspondientes
    console.log('\n📦 Movimientos correspondientes:');
    
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

    // 6. Verificar que no hay movimientos sin venta_id
    const movimientosSinVentaId = await pool.query(`
      SELECT COUNT(*) as total
      FROM movimientos_stock
      WHERE referencia NOT LIKE 'venta_id=%' AND referencia ILIKE '%venta%'
    `);
    
    console.log(`\n⚠️ Movimientos sin venta_id: ${movimientosSinVentaId.rows[0].total}`);

    // 7. Resumen final
    console.log('\n📈 Resumen final:');
    console.log(`  - Ventas reales en BD: ${totalVentas.rows[0].total}`);
    console.log(`  - Ventas únicas contadas: ${ventaIds.size}`);
    console.log(`  - Movimientos con venta_id: ${movimientosConVentaId.rows[0].total}`);
    console.log(`  - Movimientos sin venta_id: ${movimientosSinVentaId.rows[0].total}`);
    
    const diferencia = totalVentas.rows[0].total - ventaIds.size;
    if (diferencia == 0) {
      console.log(`  ✅ Los conteos coinciden perfectamente!`);
    } else {
      console.log(`  ⚠️ Diferencia: ${diferencia} ventas`);
      console.log(`  💡 Esto es normal si hay ventas antiguas sin movimientos de stock`);
    }

    console.log('\n🎉 Verificación completada!');
    console.log('💡 El frontend debería mostrar el conteo correcto y actualizarse automáticamente');

  } catch (error) {
    console.error('❌ Error en verificación:', error);
  } finally {
    await pool.end();
  }
}

verificacionFinalCompleta(); 