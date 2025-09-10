const pool = require('./config/database');

async function corregirLogicaStock() {
  try {
    console.log('🔧 Corrigiendo lógica de stock...\n');

    // 1. Verificar productos sin movimientos de stock inicial
    console.log('📊 Verificando productos sin movimientos de stock inicial...');
    const productosSinMovimientos = await pool.query(`
      SELECT a.id, a.nombre, a.stock_minimo, a.precio_compra, a.precio_venta
      FROM articulos a
      LEFT JOIN movimientos_stock ms ON a.id = ms.articulo_id
      WHERE a.activo = true 
      AND a.stock_minimo > 0 
      AND ms.id IS NULL
      ORDER BY a.id
    `);

    if (productosSinMovimientos.rows.length > 0) {
      console.log(`❌ Encontrados ${productosSinMovimientos.rows.length} productos sin movimientos de stock inicial:`);
      
      for (const producto of productosSinMovimientos.rows) {
        console.log(`  - ${producto.nombre} (ID: ${producto.id}): ${producto.stock_minimo} unidades`);
        
        // Crear movimiento de stock inicial
        await pool.query(
          'INSERT INTO movimientos_stock (articulo_id, tipo_movimiento, cantidad, stock_antes, stock_despues, referencia, fecha_hora) VALUES ($1, $2, $3, $4, $5, $6, NOW())',
          [producto.id, 'entrada', producto.stock_minimo, 0, producto.stock_minimo, 'Stock inicial (corregido)']
        );
        console.log(`    ✅ Movimiento de stock inicial creado`);
      }
    } else {
      console.log('✅ Todos los productos tienen movimientos de stock inicial');
    }

    // 2. Verificar consistencia de stock
    console.log('\n📊 Verificando consistencia de stock...');
    const inconsistencias = await pool.query(`
      SELECT 
        a.id,
        a.nombre,
        a.stock_minimo as stock_actual,
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
      ORDER BY a.id
    `);

    if (inconsistencias.rows.length > 0) {
      console.log(`❌ Encontradas ${inconsistencias.rows.length} inconsistencias en stock:`);
      
      for (const item of inconsistencias.rows) {
        console.log(`  - ${item.nombre} (ID: ${item.id}):`);
        console.log(`    Stock actual: ${item.stock_actual}`);
        console.log(`    Stock calculado: ${item.stock_calculado}`);
        
        // Corregir el stock
        await pool.query(
          'UPDATE articulos SET stock_minimo = $1 WHERE id = $2',
          [item.stock_calculado, item.id]
        );
        console.log(`    ✅ Stock corregido a ${item.stock_calculado}`);
      }
    } else {
      console.log('✅ Todos los stocks son consistentes');
    }

    // 3. Verificar movimientos duplicados
    console.log('\n📊 Verificando movimientos duplicados...');
    const duplicados = await pool.query(`
      SELECT 
        articulo_id,
        tipo_movimiento,
        referencia,
        COUNT(*) as cantidad_movimientos,
        SUM(cantidad) as cantidad_total
      FROM movimientos_stock
      WHERE referencia LIKE 'venta_id=%'
      GROUP BY articulo_id, tipo_movimiento, referencia
      HAVING COUNT(*) > 1
      ORDER BY articulo_id, referencia
    `);

    if (duplicados.rows.length > 0) {
      console.log(`❌ Encontrados ${duplicados.rows.length} grupos de movimientos duplicados:`);
      
      for (const grupo of duplicados.rows) {
        console.log(`  - Producto ID: ${grupo.articulo_id}, Referencia: ${grupo.referencia}`);
        console.log(`    ${grupo.cantidad_movimientos} movimientos, ${grupo.cantidad_total} unidades total`);
        
        // Eliminar movimientos duplicados, manteniendo solo el primero
        await pool.query(`
          DELETE FROM movimientos_stock 
          WHERE id NOT IN (
            SELECT MIN(id) 
            FROM movimientos_stock 
            WHERE articulo_id = $1 AND referencia = $2
            GROUP BY articulo_id, referencia
          )
          AND articulo_id = $1 AND referencia = $2
        `, [grupo.articulo_id, grupo.referencia]);
        
        console.log(`    ✅ Movimientos duplicados eliminados`);
      }
    } else {
      console.log('✅ No se encontraron movimientos duplicados');
    }

    // 4. Resumen final
    console.log('\n📈 Resumen final:');
    const totalProductos = await pool.query('SELECT COUNT(*) as total FROM articulos WHERE activo = true');
    const totalMovimientos = await pool.query('SELECT COUNT(*) as total FROM movimientos_stock');
    const totalVentas = await pool.query('SELECT COUNT(*) as total FROM ventas');
    
    console.log(`  - Productos activos: ${totalProductos.rows[0].total}`);
    console.log(`  - Movimientos de stock: ${totalMovimientos.rows[0].total}`);
    console.log(`  - Ventas registradas: ${totalVentas.rows[0].total}`);

    console.log('\n🎉 Corrección de lógica de stock completada!');
    console.log('💡 El sistema ahora debería funcionar correctamente');

  } catch (error) {
    console.error('❌ Error durante la corrección:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar la corrección
corregirLogicaStock();
