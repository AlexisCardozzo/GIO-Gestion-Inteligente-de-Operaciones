const pool = require('./config/database');

async function verificarMovimientosStock() {
  try {
    console.log('🔍 Verificando movimientos de stock...\n');

    // 1. Verificar estructura de la tabla
    console.log('📋 Estructura de movimientos_stock:');
    const estructura = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'movimientos_stock'
      ORDER BY ordinal_position
    `);
    
    estructura.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    // 2. Verificar movimientos recientes
    console.log('\n📊 Movimientos recientes:');
    const movimientos = await pool.query(`
      SELECT 
        ms.id,
        ms.articulo_id,
        a.nombre as producto_nombre,
        ms.tipo_movimiento,
        ms.cantidad,
        ms.stock_antes,
        ms.stock_despues,
        ms.referencia,
        ms.fecha_hora
      FROM movimientos_stock ms
      LEFT JOIN articulos a ON ms.articulo_id = a.id
      ORDER BY ms.fecha_hora DESC
      LIMIT 10
    `);

    movimientos.rows.forEach((mov, index) => {
      console.log(`  ${index + 1}. ${mov.producto_nombre} (ID: ${mov.articulo_id})`);
      console.log(`     Tipo: ${mov.tipo_movimiento}, Cantidad: ${mov.cantidad}`);
      console.log(`     Stock: ${mov.stock_antes} → ${mov.stock_despues}`);
      console.log(`     Referencia: ${mov.referencia}`);
      console.log(`     Fecha: ${mov.fecha_hora}`);
      console.log('');
    });

    // 3. Verificar si hay movimientos duplicados para la misma venta
    console.log('🔍 Verificando movimientos duplicados por venta:');
    const duplicados = await pool.query(`
      SELECT 
        referencia,
        COUNT(*) as cantidad_movimientos,
        SUM(cantidad) as cantidad_total
      FROM movimientos_stock
      WHERE referencia LIKE 'venta_id=%'
      GROUP BY referencia
      HAVING COUNT(*) > 1
      ORDER BY referencia DESC
    `);

    if (duplicados.rows.length > 0) {
      console.log('❌ Encontrados movimientos duplicados:');
      duplicados.rows.forEach(row => {
        console.log(`  - ${row.referencia}: ${row.cantidad_movimientos} movimientos, ${row.cantidad_total} unidades total`);
      });
    } else {
      console.log('✅ No se encontraron movimientos duplicados');
    }

    // 4. Verificar consistencia de stock
    console.log('\n🔍 Verificando consistencia de stock:');
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
      console.log('❌ Encontradas inconsistencias en stock:');
      inconsistencias.rows.forEach(row => {
        console.log(`  - ${row.nombre} (ID: ${row.id}): Stock actual: ${row.stock_actual}, Stock calculado: ${row.stock_calculado}`);
      });
    } else {
      console.log('✅ Todos los stocks son consistentes');
    }

  } catch (error) {
    console.error('❌ Error durante la verificación:', error);
  } finally {
    await pool.end();
  }
}

verificarMovimientosStock();
