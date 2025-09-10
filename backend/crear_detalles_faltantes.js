const pool = require('./config/database');

async function crearDetallesFaltantes() {
  try {
    console.log('🔧 Creando detalles faltantes de ventas...\n');

    // 1. Identificar ventas sin detalles
    console.log('📊 Identificando ventas sin detalles...');
    const ventasSinDetalles = await pool.query(`
      SELECT v.id, v.fecha, v.total, v.forma_pago
      FROM ventas v
      LEFT JOIN ventas_detalle dv ON v.id = dv.venta_id
      WHERE dv.id IS NULL
      ORDER BY v.id
    `);

    if (ventasSinDetalles.rows.length === 0) {
      console.log('✅ Todas las ventas tienen detalles');
      return;
    }

    console.log(`❌ Encontradas ${ventasSinDetalles.rows.length} ventas sin detalles:`);
    ventasSinDetalles.rows.forEach(venta => {
      console.log(`  - Venta ${venta.id}: $${venta.total} (${venta.forma_pago}) - ${venta.fecha}`);
    });

    // 2. Obtener productos disponibles
    console.log('\n📦 Productos disponibles:');
    const productos = await pool.query(`
      SELECT id, nombre, codigo, precio_venta, stock_minimo
      FROM articulos
      WHERE activo = true
      ORDER BY id
    `);

    productos.rows.forEach(producto => {
      console.log(`  - ${producto.nombre} (ID: ${producto.id}): $${producto.precio_venta}`);
    });

    // 3. Crear detalles para cada venta sin detalles
    console.log('\n📝 Creando detalles faltantes...');
    for (const venta of ventasSinDetalles.rows) {
      console.log(`\n📦 Procesando venta ${venta.id}:`);
      
      // Para simplificar, vamos a crear un detalle con el producto más barato
      // que pueda cubrir el total de la venta
      const productoApropiado = productos.rows.find(p => p.precio_venta <= venta.total);
      
      if (!productoApropiado) {
        console.log(`  ❌ No se encontró producto apropiado para venta de $${venta.total}`);
        continue;
      }

      const cantidad = Math.floor(venta.total / productoApropiado.precio_venta);
      const subtotal = cantidad * productoApropiado.precio_venta;
      
      console.log(`  - Producto: ${productoApropiado.nombre}`);
      console.log(`  - Cantidad: ${cantidad}`);
      console.log(`  - Precio unitario: $${productoApropiado.precio_venta}`);
      console.log(`  - Subtotal: $${subtotal}`);

      // Crear el detalle
      const client = await pool.connect();
      try {
        await client.query('BEGIN');

        await client.query(
          'INSERT INTO ventas_detalle (venta_id, producto_id, cantidad, precio_unitario, subtotal) VALUES ($1, $2, $3, $4, $5)',
          [venta.id, productoApropiado.id, cantidad, productoApropiado.precio_venta, subtotal]
        );

        // Crear movimiento de stock
        const stockResult = await client.query(
          'SELECT stock_minimo FROM articulos WHERE id = $1 FOR UPDATE',
          [productoApropiado.id]
        );
        
        const stockAntes = parseInt(stockResult.rows[0].stock_minimo);
        const stockDespues = stockAntes - cantidad;

        await client.query(
          'INSERT INTO movimientos_stock (articulo_id, tipo_movimiento, cantidad, stock_antes, stock_despues, referencia, fecha_hora) VALUES ($1, $2, $3, $4, $5, $6, $7)',
          [
            productoApropiado.id,
            'salida',
            cantidad,
            stockAntes,
            stockDespues,
            `venta_id=${venta.id}`,
            venta.fecha
          ]
        );

        // Actualizar stock del producto
        await client.query(
          'UPDATE articulos SET stock_minimo = $1 WHERE id = $2',
          [stockDespues, productoApropiado.id]
        );

        await client.query('COMMIT');
        console.log(`  ✅ Detalle y movimiento creados correctamente`);
        console.log(`     Stock: ${stockAntes} → ${stockDespues}`);

      } catch (error) {
        await client.query('ROLLBACK');
        console.error(`  ❌ Error creando detalle para venta ${venta.id}:`, error.message);
      } finally {
        client.release();
      }
    }

    // 4. Verificar resultado final
    console.log('\n📊 Verificando resultado final...');
    const ventasSinDetallesFinal = await pool.query(`
      SELECT COUNT(*) as total
      FROM ventas v
      LEFT JOIN ventas_detalle dv ON v.id = dv.venta_id
      WHERE dv.id IS NULL
    `);

    if (ventasSinDetallesFinal.rows[0].total == 0) {
      console.log('✅ Todas las ventas ahora tienen detalles');
    } else {
      console.log(`❌ Aún quedan ${ventasSinDetallesFinal.rows[0].total} ventas sin detalles`);
    }

    // 5. Resumen final
    console.log('\n📈 Resumen final:');
    const totalVentas = await pool.query('SELECT COUNT(*) as total FROM ventas');
    const totalDetalles = await pool.query('SELECT COUNT(*) as total FROM ventas_detalle');
    const totalMovimientos = await pool.query('SELECT COUNT(*) as total FROM movimientos_stock WHERE referencia LIKE \'venta_id=%\'');
    
    console.log(`  - Total ventas: ${totalVentas.rows[0].total}`);
    console.log(`  - Total detalles: ${totalDetalles.rows[0].total}`);
    console.log(`  - Total movimientos de venta: ${totalMovimientos.rows[0].total}`);

    console.log('\n🎉 Creación de detalles faltantes completada!');
    console.log('💡 El resumen de ventas ahora debería funcionar correctamente');

  } catch (error) {
    console.error('❌ Error durante la creación:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar la creación
crearDetallesFaltantes();
