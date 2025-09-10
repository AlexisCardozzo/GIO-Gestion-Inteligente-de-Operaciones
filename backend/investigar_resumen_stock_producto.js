const pool = require('./config/database');

async function investigarResumenStockProducto() {
  try {
    console.log('🔍 Investigando resumen de stock por producto...\n');

    // 1. Verificar productos existentes
    console.log('📊 Productos disponibles:');
    const productos = await pool.query(`
      SELECT id, nombre, codigo, stock_minimo, activo
      FROM articulos
      WHERE activo = true
      ORDER BY id
    `);

    if (productos.rows.length === 0) {
      console.log('  - No hay productos activos');
      return;
    }

    productos.rows.forEach(producto => {
      console.log(`  - ID: ${producto.id} | ${producto.nombre} (${producto.codigo}) | Stock: ${producto.stock_minimo}`);
    });

    // 2. Analizar movimientos de stock por producto
    console.log('\n📦 Análisis de movimientos por producto:');
    for (const producto of productos.rows) {
      console.log(`\n🔍 Producto: ${producto.nombre} (ID: ${producto.id})`);
      
      // Obtener todos los movimientos del producto
      const movimientos = await pool.query(`
        SELECT 
          id,
          tipo_movimiento,
          cantidad,
          stock_antes,
          stock_despues,
          referencia,
          fecha_hora
        FROM movimientos_stock
        WHERE articulo_id = $1
        ORDER BY fecha_hora ASC
      `, [producto.id]);

      if (movimientos.rows.length === 0) {
        console.log(`  ❌ No hay movimientos registrados`);
        continue;
      }

      // Calcular resumen manualmente
      let totalEntradas = 0;
      let totalSalidas = 0;
      let stockCalculado = 0;

      console.log(`  📋 Movimientos (${movimientos.rows.length} total):`);
      movimientos.rows.forEach((mov, index) => {
        const cambio = mov.tipo_movimiento === 'entrada' ? mov.cantidad : -mov.cantidad;
        stockCalculado += cambio;
        
        if (mov.tipo_movimiento === 'entrada') {
          totalEntradas += mov.cantidad;
        } else {
          totalSalidas += mov.cantidad;
        }

        console.log(`    ${index + 1}. ${mov.tipo_movimiento.toUpperCase()}: ${mov.cantidad} unidades`);
        console.log(`       Stock: ${mov.stock_antes} → ${mov.stock_despues} (calculado: ${stockCalculado})`);
        console.log(`       Referencia: ${mov.referencia}`);
        console.log(`       Fecha: ${mov.fecha_hora}`);
      });

      console.log(`  📊 Resumen calculado:`);
      console.log(`    - Total entradas: ${totalEntradas}`);
      console.log(`    - Total salidas: ${totalSalidas}`);
      console.log(`    - Stock actual calculado: ${stockCalculado}`);
      console.log(`    - Stock en BD: ${producto.stock_minimo}`);
      console.log(`    - Diferencia: ${producto.stock_minimo - stockCalculado}`);

      // Verificar ventas asociadas
      const ventasProducto = await pool.query(`
        SELECT 
          v.id as venta_id,
          v.fecha,
          v.total,
          dv.cantidad,
          dv.precio_unitario
        FROM ventas_detalle dv
        JOIN ventas v ON dv.venta_id = v.id
        WHERE dv.producto_id = $1
        ORDER BY v.fecha DESC
      `, [producto.id]);

      if (ventasProducto.rows.length > 0) {
        console.log(`  🛒 Ventas asociadas (${ventasProducto.rows.length}):`);
        ventasProducto.rows.forEach(venta => {
          console.log(`    - Venta ${venta.venta_id}: ${venta.cantidad} unidades a $${venta.precio_unitario} - ${venta.fecha}`);
        });
      } else {
        console.log(`  ⚠️ No hay ventas registradas para este producto`);
      }
    }

    // 3. Verificar movimientos de venta globales
    console.log('\n🛒 Análisis de movimientos de venta:');
    const movimientosVenta = await pool.query(`
      SELECT 
        ms.id,
        ms.articulo_id,
        a.nombre as producto_nombre,
        ms.tipo_movimiento,
        ms.cantidad,
        ms.referencia,
        ms.fecha_hora
      FROM movimientos_stock ms
      JOIN articulos a ON ms.articulo_id = a.id
      WHERE ms.referencia LIKE 'venta_id=%'
      ORDER BY ms.fecha_hora DESC
    `);

    if (movimientosVenta.rows.length > 0) {
      console.log(`  📦 Movimientos de venta (${movimientosVenta.rows.length}):`);
      movimientosVenta.rows.forEach(mov => {
        console.log(`    - ${mov.producto_nombre}: ${mov.tipo_movimiento} ${mov.cantidad} unidades - ${mov.referencia}`);
      });
    } else {
      console.log(`  ❌ No hay movimientos de venta registrados`);
    }

    // 4. Verificar inconsistencias
    console.log('\n🔍 Verificando inconsistencias:');
    const inconsistencias = await pool.query(`
      SELECT 
        a.id,
        a.nombre,
        a.stock_minimo as stock_bd,
        COALESCE(SUM(
          CASE 
            WHEN ms.tipo_movimiento = 'entrada' THEN ms.cantidad
            WHEN ms.tipo_movimiento = 'salida' THEN -ms.cantidad
            ELSE 0
          END
        ), 0) as stock_calculado
      FROM articulos a
      LEFT JOIN movimientos_stock ms ON a.id = ms.articulo_id
      WHERE a.activo = true
      GROUP BY a.id, a.nombre, a.stock_minimo
      HAVING ABS(a.stock_minimo - COALESCE(SUM(
        CASE 
          WHEN ms.tipo_movimiento = 'entrada' THEN ms.cantidad
          WHEN ms.tipo_movimiento = 'salida' THEN -ms.cantidad
          ELSE 0
        END
      ), 0)) > 0
    `);

    if (inconsistencias.rows.length > 0) {
      console.log(`  ❌ Encontradas ${inconsistencias.rows.length} inconsistencias:`);
      inconsistencias.rows.forEach(item => {
        console.log(`    - ${item.nombre}: BD=${item.stock_bd}, Calculado=${item.stock_calculado}`);
      });
    } else {
      console.log(`  ✅ No se encontraron inconsistencias`);
    }

    console.log('\n🎯 Diagnóstico completado!');
    console.log('💡 Revisa los resultados para identificar el problema específico');

  } catch (error) {
    console.error('❌ Error durante la investigación:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar la investigación
investigarResumenStockProducto();
