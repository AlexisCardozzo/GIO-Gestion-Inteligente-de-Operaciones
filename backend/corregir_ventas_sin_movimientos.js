const pool = require('./config/database');

async function corregirVentasSinMovimientos() {
  try {
    console.log('🔧 Corrigiendo ventas sin movimientos de stock...\n');

    // 1. Obtener ventas sin movimientos de stock
    console.log('📊 Identificando ventas sin movimientos de stock...');
    const ventasSinMovimientos = await pool.query(`
      SELECT v.id, v.fecha, v.total, v.forma_pago
      FROM ventas v
      LEFT JOIN movimientos_stock ms ON ms.referencia LIKE 'venta_id=' || v.id
      WHERE ms.id IS NULL
      ORDER BY v.fecha ASC
    `);

    if (ventasSinMovimientos.rows.length === 0) {
      console.log('✅ Todas las ventas tienen movimientos de stock asociados');
      return;
    }

    console.log(`❌ Encontradas ${ventasSinMovimientos.rows.length} ventas sin movimientos de stock:`);
    ventasSinMovimientos.rows.forEach(venta => {
      console.log(`  - Venta ${venta.id}: $${venta.total} (${venta.forma_pago}) - ${venta.fecha}`);
    });

    // 2. Obtener detalles de estas ventas
    console.log('\n📊 Obteniendo detalles de las ventas...');
    for (const venta of ventasSinMovimientos.rows) {
      const detalles = await pool.query(`
        SELECT 
          dv.producto_id,
          dv.cantidad,
          dv.precio_unitario,
          a.nombre as producto_nombre,
          a.stock_minimo as stock_actual
        FROM ventas_detalle dv
        LEFT JOIN articulos a ON dv.producto_id = a.id
        WHERE dv.venta_id = $1
      `, [venta.id]);

      if (detalles.rows.length === 0) {
        console.log(`  ⚠️ Venta ${venta.id} no tiene detalles`);
        continue;
      }

      console.log(`\n📦 Procesando venta ${venta.id}:`);
      detalles.rows.forEach(detalle => {
        console.log(`  - ${detalle.producto_nombre}: ${detalle.cantidad} unidades a $${detalle.precio_unitario}`);
      });

      // 3. Crear movimientos de stock para cada detalle
      const client = await pool.connect();
      try {
        await client.query('BEGIN');

        for (const detalle of detalles.rows) {
          // Obtener stock actual con bloqueo
          const stockResult = await client.query(
            'SELECT stock_minimo FROM articulos WHERE id = $1 FOR UPDATE',
            [detalle.producto_id]
          );
          
          if (stockResult.rows.length === 0) {
            console.log(`    ❌ Producto ${detalle.producto_id} no encontrado`);
            continue;
          }

          const stockAntes = parseInt(stockResult.rows[0].stock_minimo);
          const stockDespues = stockAntes - detalle.cantidad;

          // Crear movimiento de stock
          await client.query(
            'INSERT INTO movimientos_stock (articulo_id, tipo_movimiento, cantidad, stock_antes, stock_despues, referencia, fecha_hora) VALUES ($1, $2, $3, $4, $5, $6, $7)',
            [
              detalle.producto_id,
              'salida',
              detalle.cantidad,
              stockAntes,
              stockDespues,
              `venta_id=${venta.id}`,
              venta.fecha // Usar la fecha de la venta
            ]
          );

          // Actualizar stock del producto
          await client.query(
            'UPDATE articulos SET stock_minimo = $1 WHERE id = $2',
            [stockDespues, detalle.producto_id]
          );

          console.log(`    ✅ Movimiento creado para ${detalle.producto_nombre}: ${detalle.cantidad} unidades`);
          console.log(`       Stock: ${stockAntes} → ${stockDespues}`);
        }

        await client.query('COMMIT');
        console.log(`  ✅ Venta ${venta.id} procesada correctamente`);

      } catch (error) {
        await client.query('ROLLBACK');
        console.error(`  ❌ Error procesando venta ${venta.id}:`, error.message);
      } finally {
        client.release();
      }
    }

    // 4. Verificar resultado final
    console.log('\n📊 Verificando resultado final...');
    const ventasSinMovimientosFinal = await pool.query(`
      SELECT COUNT(*) as total
      FROM ventas v
      LEFT JOIN movimientos_stock ms ON ms.referencia LIKE 'venta_id=' || v.id
      WHERE ms.id IS NULL
    `);

    if (ventasSinMovimientosFinal.rows[0].total == 0) {
      console.log('✅ Todas las ventas ahora tienen movimientos de stock asociados');
    } else {
      console.log(`❌ Aún quedan ${ventasSinMovimientosFinal.rows[0].total} ventas sin movimientos`);
    }

    // 5. Resumen final
    console.log('\n📈 Resumen final:');
    const totalVentas = await pool.query('SELECT COUNT(*) as total FROM ventas');
    const totalMovimientos = await pool.query('SELECT COUNT(*) as total FROM movimientos_stock WHERE referencia LIKE \'venta_id=%\'');
    
    console.log(`  - Total ventas: ${totalVentas.rows[0].total}`);
    console.log(`  - Total movimientos de venta: ${totalMovimientos.rows[0].total}`);

    console.log('\n🎉 Corrección de ventas sin movimientos completada!');
    console.log('💡 El resumen de ventas ahora debería funcionar correctamente');

  } catch (error) {
    console.error('❌ Error durante la corrección:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar la corrección
corregirVentasSinMovimientos();
