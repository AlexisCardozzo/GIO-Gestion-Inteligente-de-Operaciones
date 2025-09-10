const pool = require('./config/database');

async function crearMovimientoSalidaFaltante() {
  try {
    console.log('🔧 Creando movimiento de salida faltante...\n');

    // 1. Verificar ventas sin movimientos de salida
    console.log('📊 Verificando ventas sin movimientos de salida...');
    const ventasSinMovimientoSalida = await pool.query(`
      SELECT 
        v.id as venta_id,
        v.fecha,
        v.total,
        dv.producto_id,
        dv.cantidad,
        dv.precio_unitario,
        a.nombre as producto_nombre,
        a.stock_minimo as stock_actual
      FROM ventas v
      JOIN ventas_detalle dv ON v.id = dv.venta_id
      JOIN articulos a ON dv.producto_id = a.id
      WHERE NOT EXISTS (
        SELECT 1 FROM movimientos_stock ms 
        WHERE ms.referencia = 'venta_id=' || v.id 
        AND ms.articulo_id = dv.producto_id
      )
      ORDER BY v.fecha ASC
    `);

    if (ventasSinMovimientoSalida.rows.length === 0) {
      console.log('✅ Todas las ventas tienen movimientos de salida registrados');
      return;
    }

    console.log(`❌ Encontradas ${ventasSinMovimientoSalida.rows.length} ventas sin movimientos de salida:`);
    ventasSinMovimientoSalida.rows.forEach(venta => {
      console.log(`  - Venta ${venta.venta_id}: ${venta.producto_nombre} - ${venta.cantidad} unidades - ${venta.fecha}`);
    });

    // 2. Crear movimientos de salida faltantes
    console.log('\n📦 Creando movimientos de salida...');
    for (const venta of ventasSinMovimientoSalida.rows) {
      console.log(`\n🔍 Procesando venta ${venta.venta_id}:`);
      console.log(`  - Producto: ${venta.producto_nombre}`);
      console.log(`  - Cantidad: ${venta.cantidad}`);
      console.log(`  - Stock actual: ${venta.stock_actual}`);

      const client = await pool.connect();
      try {
        await client.query('BEGIN');

        // Obtener stock actual con bloqueo
        const stockResult = await client.query(
          'SELECT stock_minimo FROM articulos WHERE id = $1 FOR UPDATE',
          [venta.producto_id]
        );
        
        const stockAntes = parseInt(stockResult.rows[0].stock_minimo);
        const stockDespues = stockAntes - venta.cantidad;

        // Crear movimiento de salida
        await client.query(
          'INSERT INTO movimientos_stock (articulo_id, tipo_movimiento, cantidad, stock_antes, stock_despues, referencia, fecha_hora) VALUES ($1, $2, $3, $4, $5, $6, $7)',
          [
            venta.producto_id,
            'salida',
            venta.cantidad,
            stockAntes,
            stockDespues,
            `venta_id=${venta.venta_id}`,
            venta.fecha
          ]
        );

        // Actualizar stock del producto
        await client.query(
          'UPDATE articulos SET stock_minimo = $1 WHERE id = $2',
          [stockDespues, venta.producto_id]
        );

        await client.query('COMMIT');
        console.log(`  ✅ Movimiento de salida creado`);
        console.log(`     Stock: ${stockAntes} → ${stockDespues}`);

      } catch (error) {
        await client.query('ROLLBACK');
        console.error(`  ❌ Error creando movimiento para venta ${venta.venta_id}:`, error.message);
      } finally {
        client.release();
      }
    }

    // 3. Verificar resultado
    console.log('\n📊 Verificando resultado...');
    const ventasSinMovimientoFinal = await pool.query(`
      SELECT COUNT(*) as total
      FROM ventas v
      JOIN ventas_detalle dv ON v.id = dv.venta_id
      WHERE NOT EXISTS (
        SELECT 1 FROM movimientos_stock ms 
        WHERE ms.referencia = 'venta_id=' || v.id 
        AND ms.articulo_id = dv.producto_id
      )
    `);

    if (ventasSinMovimientoFinal.rows[0].total == 0) {
      console.log('✅ Todas las ventas ahora tienen movimientos de salida');
    } else {
      console.log(`❌ Aún quedan ${ventasSinMovimientoFinal.rows[0].total} ventas sin movimientos`);
    }

    // 4. Mostrar resumen final
    console.log('\n📈 Resumen final:');
    const totalMovimientos = await pool.query('SELECT COUNT(*) as total FROM movimientos_stock WHERE tipo_movimiento = \'salida\'');
    const totalVentas = await pool.query('SELECT COUNT(*) as total FROM ventas');
    
    console.log(`  - Total movimientos de salida: ${totalMovimientos.rows[0].total}`);
    console.log(`  - Total ventas: ${totalVentas.rows[0].total}`);

    console.log('\n🎉 Creación de movimientos de salida completada!');
    console.log('💡 El resumen de stock por producto ahora debería mostrar correctamente las salidas');

  } catch (error) {
    console.error('❌ Error durante la creación:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar la creación
crearMovimientoSalidaFaltante();
