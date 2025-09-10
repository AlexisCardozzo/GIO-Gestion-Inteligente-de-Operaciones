const pool = require('./config/database');

async function diagnosticoMovimientosVentas() {
  try {
    console.log('🔍 Diagnóstico de movimientos de ventas...\n');

    // 1. Verificar movimientos de stock por venta
    console.log('📊 Movimientos de stock por venta:');
    
    const movimientosVentas = await pool.query(`
      SELECT 
        ms.id,
        ms.fecha_hora,
        ms.tipo_movimiento as tipo,
        ms.referencia as motivo,
        ms.cantidad,
        ms.articulo_id,
        a.nombre as producto_nombre,
        v.id as venta_id,
        v.fecha as venta_fecha,
        v.total as venta_total
      FROM movimientos_stock ms
      LEFT JOIN articulos a ON ms.articulo_id = a.id
      LEFT JOIN ventas v ON ms.referencia LIKE '%venta%' AND ms.referencia ~ 'venta_id=([0-9]+)'
      WHERE ms.referencia ILIKE '%venta%'
      ORDER BY ms.fecha_hora DESC
      LIMIT 20
    `);
    
    console.log(`Total movimientos de venta: ${movimientosVentas.rows.length}`);
    
    // Agrupar por venta para ver el conteo
    const ventasUnicas = new Map();
    const ventasPorMinuto = new Map();
    
    movimientosVentas.rows.forEach(mov => {
      const ventaId = mov.venta_id;
      const fecha = new Date(mov.fecha_hora);
      const claveMinuto = `${fecha.getFullYear()}-${fecha.getMonth()+1}-${fecha.getDate()}-${fecha.getHours()}-${fecha.getMinutes()}`;
      
      // Contar por venta ID
      if (ventaId) {
        ventasUnicas.set(ventaId, (ventasUnicas.get(ventaId) || 0) + 1);
      }
      
      // Contar por minuto (como hace el frontend)
      ventasPorMinuto.set(claveMinuto, (ventasPorMinuto.get(claveMinuto) || 0) + 1);
    });
    
    console.log('\n📈 Conteo por venta ID:');
    console.log(`  - Ventas únicas por ID: ${ventasUnicas.size}`);
    ventasUnicas.forEach((count, ventaId) => {
      console.log(`    - Venta ${ventaId}: ${count} movimientos`);
    });
    
    console.log('\n⏰ Conteo por minuto (como frontend):');
    console.log(`  - Ventas únicas por minuto: ${ventasPorMinuto.size}`);
    ventasPorMinuto.forEach((count, clave) => {
      console.log(`    - ${clave}: ${count} movimientos`);
    });

    // 2. Verificar ventas reales en la base de datos
    console.log('\n🛒 Ventas reales en la base de datos:');
    
    const ventasReales = await pool.query(`
      SELECT 
        v.id,
        v.fecha,
        v.total,
        v.forma_pago,
        c.nombre as cliente_nombre,
        COUNT(vd.id) as total_detalles
      FROM ventas v
      LEFT JOIN clientes c ON v.cliente_id = c.id
      LEFT JOIN ventas_detalle vd ON v.id = vd.venta_id
      GROUP BY v.id, v.fecha, v.total, v.forma_pago, c.nombre
      ORDER BY v.fecha DESC
      LIMIT 10
    `);
    
    console.log(`Total ventas en BD: ${ventasReales.rows.length}`);
    ventasReales.rows.forEach(venta => {
      console.log(`  - Venta ${venta.id}: $${venta.total} (${venta.forma_pago}) - ${venta.cliente_nombre} - ${venta.total_detalles} detalles`);
    });

    // 3. Verificar movimientos sin venta_id
    console.log('\n⚠️ Movimientos sin venta_id:');
    
    const movimientosSinVenta = await pool.query(`
      SELECT 
        ms.id,
        ms.fecha_hora,
        ms.tipo_movimiento as tipo,
        ms.referencia as motivo,
        ms.cantidad,
        ms.articulo_id,
        a.nombre as producto_nombre
      FROM movimientos_stock ms
      LEFT JOIN articulos a ON ms.articulo_id = a.id
      WHERE ms.referencia ILIKE '%venta%' AND ms.referencia NOT LIKE '%venta_id=%'
      ORDER BY ms.fecha_hora DESC
    `);
    
    if (movimientosSinVenta.rows.length > 0) {
      console.log(`Movimientos sin venta_id: ${movimientosSinVenta.rows.length}`);
      movimientosSinVenta.rows.forEach(mov => {
        console.log(`  - ID ${mov.id}: ${mov.producto_nombre} x${mov.cantidad} (${mov.fecha_hora})`);
      });
    } else {
      console.log('✅ Todos los movimientos tienen venta_id');
    }

    // 4. Comparar conteos
    console.log('\n📊 Comparación de conteos:');
    console.log(`  - Ventas reales en BD: ${ventasReales.rows.length}`);
    console.log(`  - Ventas únicas por ID: ${ventasUnicas.size}`);
    console.log(`  - Ventas únicas por minuto: ${ventasPorMinuto.size}`);
    
    const diferencia = ventasReales.rows.length - ventasPorMinuto.size;
    if (diferencia != 0) {
      console.log(`  ⚠️ Diferencia: ${diferencia} ventas`);
      console.log(`  💡 Esto explica por qué el frontend muestra ${ventasPorMinuto.size} en lugar de ${ventasReales.rows.length}`);
    } else {
      console.log(`  ✅ Los conteos coinciden`);
    }

    console.log('\n🎉 Diagnóstico completado!');

  } catch (error) {
    console.error('❌ Error en diagnóstico:', error);
  } finally {
    await pool.end();
  }
}

diagnosticoMovimientosVentas(); 