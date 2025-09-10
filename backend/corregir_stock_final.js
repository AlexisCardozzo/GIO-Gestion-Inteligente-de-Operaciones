const pool = require('./config/database');

async function corregirStockFinal() {
  try {
    console.log('🔧 Corrigiendo stock final...\n');

    // 1. Verificar productos con inconsistencias
    console.log('📊 Verificando inconsistencias de stock...');
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

    if (inconsistencias.rows.length === 0) {
      console.log('✅ No hay inconsistencias de stock');
      return;
    }

    console.log(`❌ Encontradas ${inconsistencias.rows.length} inconsistencias:`);
    inconsistencias.rows.forEach(item => {
      console.log(`  - ${item.nombre}: BD=${item.stock_bd}, Calculado=${item.stock_calculado}`);
    });

    // 2. Corregir cada inconsistencia
    console.log('\n🔧 Corrigiendo inconsistencias...');
    for (const item of inconsistencias.rows) {
      console.log(`\n📦 Corrigiendo ${item.nombre}:`);
      console.log(`  - Stock actual en BD: ${item.stock_bd}`);
      console.log(`  - Stock calculado: ${item.stock_calculado}`);

      // Actualizar el stock en la base de datos
      await pool.query(
        'UPDATE articulos SET stock_minimo = $1 WHERE id = $2',
        [item.stock_calculado, item.id]
      );

      console.log(`  ✅ Stock corregido a ${item.stock_calculado}`);
    }

    // 3. Verificar resultado final
    console.log('\n📊 Verificando resultado final...');
    const inconsistenciasFinal = await pool.query(`
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

    if (inconsistenciasFinal.rows.length === 0) {
      console.log('✅ Todas las inconsistencias han sido corregidas');
    } else {
      console.log(`❌ Aún quedan ${inconsistenciasFinal.rows.length} inconsistencias`);
    }

    // 4. Mostrar estado final de productos
    console.log('\n📈 Estado final de productos:');
    const productosFinal = await pool.query(`
      SELECT 
        a.id,
        a.nombre,
        a.codigo,
        a.stock_minimo,
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
      GROUP BY a.id, a.nombre, a.codigo, a.stock_minimo
      ORDER BY a.id
    `);

    productosFinal.rows.forEach(producto => {
      console.log(`  - ${producto.nombre} (${producto.codigo}):`);
      console.log(`    Stock BD: ${producto.stock_minimo}`);
      console.log(`    Stock calculado: ${producto.stock_calculado}`);
    });

    console.log('\n🎉 Corrección de stock completada!');
    console.log('💡 El resumen de stock por producto ahora debería ser consistente');

  } catch (error) {
    console.error('❌ Error durante la corrección:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar la corrección
corregirStockFinal();
