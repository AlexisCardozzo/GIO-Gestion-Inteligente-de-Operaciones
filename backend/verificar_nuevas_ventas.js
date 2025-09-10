const pool = require('./config/database');

async function verificarNuevasVentas() {
  try {
    console.log('🔍 Verificando nuevas ventas y movimientos...\n');

    // 1. Verificar ventas más recientes
    console.log('📊 Últimas 5 ventas:');
    
    const ultimasVentas = await pool.query(`
      SELECT id, fecha, total, forma_pago
      FROM ventas
      ORDER BY fecha DESC
      LIMIT 5
    `);
    
    ultimasVentas.rows.forEach(venta => {
      console.log(`  - Venta ${venta.id}: $${venta.total} (${venta.forma_pago}) - ${venta.fecha}`);
    });

    // 2. Verificar movimientos más recientes
    console.log('\n📦 Últimos 5 movimientos:');
    
    const ultimosMovimientos = await pool.query(`
      SELECT ms.id, ms.referencia, ms.fecha_hora, a.nombre as producto
      FROM movimientos_stock ms
      LEFT JOIN articulos a ON ms.articulo_id = a.id
      ORDER BY ms.fecha_hora DESC
      LIMIT 5
    `);
    
    ultimosMovimientos.rows.forEach(mov => {
      console.log(`  - Movimiento ${mov.id}: ${mov.producto} - "${mov.referencia}" - ${mov.fecha_hora}`);
    });

    // 3. Verificar movimientos con venta_id
    console.log('\n✅ Movimientos con venta_id:');
    
    const movimientosConVentaId = await pool.query(`
      SELECT ms.id, ms.referencia, ms.fecha_hora, a.nombre as producto
      FROM movimientos_stock ms
      LEFT JOIN articulos a ON ms.articulo_id = a.id
      WHERE ms.referencia LIKE 'venta_id=%'
      ORDER BY ms.fecha_hora DESC
      LIMIT 5
    `);
    
    movimientosConVentaId.rows.forEach(mov => {
      console.log(`  - Movimiento ${mov.id}: ${mov.producto} - ${mov.referencia} - ${mov.fecha_hora}`);
    });

    // 4. Verificar movimientos sin venta_id
    console.log('\n⚠️ Movimientos sin venta_id:');
    
    const movimientosSinVentaId = await pool.query(`
      SELECT ms.id, ms.referencia, ms.fecha_hora, a.nombre as producto
      FROM movimientos_stock ms
      LEFT JOIN articulos a ON ms.articulo_id = a.id
      WHERE ms.referencia NOT LIKE 'venta_id=%' AND ms.referencia ILIKE '%venta%'
      ORDER BY ms.fecha_hora DESC
      LIMIT 5
    `);
    
    if (movimientosSinVentaId.rows.length > 0) {
      movimientosSinVentaId.rows.forEach(mov => {
        console.log(`  - Movimiento ${mov.id}: ${mov.producto} - "${mov.referencia}" - ${mov.fecha_hora}`);
      });
    } else {
      console.log('  ✅ No hay movimientos sin venta_id');
    }

    // 5. Contar ventas únicas
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
    
    console.log(`\n📈 Total ventas únicas: ${ventaIds.size}`);
    console.log('IDs de ventas:', Array.from(ventaIds).sort((a, b) => parseInt(a) - parseInt(b)));

    console.log('\n🎉 Verificación completada!');

  } catch (error) {
    console.error('❌ Error en verificación:', error);
  } finally {
    await pool.end();
  }
}

verificarNuevasVentas(); 