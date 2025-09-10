const pool = require('./config/database');

async function corregirResumenVentas() {
  try {
    console.log('🔧 Corrigiendo resumen de ventas...\n');

    // 1. Verificar ventas sin movimientos de stock
    console.log('📊 Verificando ventas sin movimientos de stock...');
    const ventasSinMovimientos = await pool.query(`
      SELECT v.id, v.fecha, v.total, v.forma_pago
      FROM ventas v
      LEFT JOIN movimientos_stock ms ON ms.referencia LIKE 'venta_id=' || v.id
      WHERE ms.id IS NULL
      ORDER BY v.fecha DESC
    `);

    if (ventasSinMovimientos.rows.length > 0) {
      console.log(`❌ Encontradas ${ventasSinMovimientos.rows.length} ventas sin movimientos de stock:`);
      ventasSinMovimientos.rows.forEach(venta => {
        console.log(`  - Venta ${venta.id}: $${venta.total} (${venta.forma_pago}) - ${venta.fecha}`);
      });
      console.log('💡 Estas ventas pueden ser antiguas o tener problemas de sincronización');
    } else {
      console.log('✅ Todas las ventas tienen movimientos de stock asociados');
    }

    // 2. Verificar movimientos de stock sin venta correspondiente
    console.log('\n📊 Verificando movimientos de stock sin venta correspondiente...');
    const movimientosSinVenta = await pool.query(`
      SELECT ms.id, ms.referencia, ms.fecha_hora, a.nombre as producto
      FROM movimientos_stock ms
      LEFT JOIN articulos a ON ms.articulo_id = a.id
      WHERE ms.referencia LIKE 'venta_id=%'
      AND NOT EXISTS (
        SELECT 1 FROM ventas v 
        WHERE ms.referencia LIKE 'venta_id=' || v.id
      )
      ORDER BY ms.fecha_hora DESC
    `);

    if (movimientosSinVenta.rows.length > 0) {
      console.log(`❌ Encontrados ${movimientosSinVenta.rows.length} movimientos sin venta correspondiente:`);
      movimientosSinVenta.rows.forEach(mov => {
        console.log(`  - Movimiento ${mov.id}: ${mov.producto} - ${mov.referencia} - ${mov.fecha_hora}`);
      });
    } else {
      console.log('✅ Todos los movimientos tienen ventas correspondientes');
    }

    // 3. Calcular resumen correcto
    console.log('\n📈 Calculando resumen correcto de ventas...');
    const resumenCorrecto = await pool.query(`
      SELECT 
        COUNT(DISTINCT v.id) as total_ventas,
        SUM(dv.cantidad) as total_productos_vendidos,
        SUM(dv.cantidad * dv.precio_unitario) as total_ventas_valor,
        SUM(dv.cantidad * (dv.precio_unitario - a.precio_compra)) as ganancia_bruta,
        SUM(dv.cantidad * (dv.precio_unitario - a.precio_compra) * (1 - COALESCE(a.iva, 0) / 100)) as ganancia_neta
      FROM ventas v
      LEFT JOIN ventas_detalle dv ON v.id = dv.venta_id
      LEFT JOIN articulos a ON dv.producto_id = a.id
      WHERE v.fecha >= CURRENT_DATE - INTERVAL '30 days'
    `);

    const resumen = resumenCorrecto.rows[0];
    console.log('📊 Resumen de ventas (últimos 30 días):');
    console.log(`  - Total ventas: ${resumen.total_ventas || 0}`);
    console.log(`  - Total productos vendidos: ${resumen.total_productos_vendidos || 0}`);
    console.log(`  - Valor total ventas: $${resumen.total_ventas_valor || 0}`);
    console.log(`  - Ganancia bruta: $${resumen.ganancia_bruta || 0}`);
    console.log(`  - Ganancia neta: $${resumen.ganancia_neta || 0}`);

    // 4. Verificar productos más vendidos
    console.log('\n📊 Productos más vendidos:');
    const productosMasVendidos = await pool.query(`
      SELECT 
        a.nombre,
        a.codigo,
        SUM(dv.cantidad) as cantidad_vendida,
        SUM(dv.cantidad * dv.precio_unitario) as valor_vendido
      FROM ventas_detalle dv
      LEFT JOIN articulos a ON dv.producto_id = a.id
      LEFT JOIN ventas v ON dv.venta_id = v.id
      WHERE v.fecha >= CURRENT_DATE - INTERVAL '30 days'
      GROUP BY a.id, a.nombre, a.codigo
      ORDER BY cantidad_vendida DESC
      LIMIT 10
    `);

    productosMasVendidos.rows.forEach((producto, index) => {
      console.log(`  ${index + 1}. ${producto.nombre} (${producto.codigo})`);
      console.log(`     Cantidad vendida: ${producto.cantidad_vendida || 0}`);
      console.log(`     Valor vendido: $${producto.valor_vendido || 0}`);
    });

    // 5. Verificar movimientos de stock por venta
    console.log('\n📊 Movimientos de stock por venta:');
    const movimientosPorVenta = await pool.query(`
      SELECT 
        ms.referencia,
        COUNT(*) as cantidad_movimientos,
        SUM(ms.cantidad) as cantidad_total
      FROM movimientos_stock ms
      WHERE ms.referencia LIKE 'venta_id=%'
      GROUP BY ms.referencia
      ORDER BY ms.referencia DESC
      LIMIT 10
    `);

    movimientosPorVenta.rows.forEach(mov => {
      console.log(`  - ${mov.referencia}: ${mov.cantidad_movimientos} movimientos, ${mov.cantidad_total} unidades`);
    });

    console.log('\n🎉 Corrección de resumen de ventas completada!');
    console.log('💡 El frontend debería mostrar el conteo correcto');

  } catch (error) {
    console.error('❌ Error durante la corrección:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar la corrección
corregirResumenVentas();
