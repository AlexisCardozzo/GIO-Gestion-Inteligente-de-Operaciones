const pool = require('./config/database');

async function debugStockCalculo() {
  try {
    console.log('🔍 Debuggeando cálculo de stock...\n');

    const productoId = 1;
    
    // 1. Obtener stock actual
    const stockActual = await pool.query('SELECT stock_minimo FROM articulos WHERE id = $1', [productoId]);
    console.log(`📊 Stock actual en la base de datos: ${stockActual.rows[0].stock_minimo}`);

    // 2. Obtener todos los movimientos ordenados por fecha
    const movimientos = await pool.query(`
      SELECT 
        ms.id,
        ms.tipo_movimiento,
        ms.cantidad,
        ms.stock_antes,
        ms.stock_despues,
        ms.referencia,
        ms.fecha_hora
      FROM movimientos_stock ms
      WHERE ms.articulo_id = $1
      ORDER BY ms.fecha_hora ASC
    `, [productoId]);

    console.log('\n📋 Movimientos en orden cronológico:');
    let stockCalculado = 0;
    movimientos.rows.forEach((mov, index) => {
      const cambio = mov.tipo_movimiento === 'entrada' ? mov.cantidad : -mov.cantidad;
      const stockAnterior = stockCalculado;
      stockCalculado += cambio;
      
      console.log(`  ${index + 1}. ${mov.tipo_movimiento.toUpperCase()}: ${mov.cantidad} unidades`);
      console.log(`     Stock antes (movimiento): ${mov.stock_antes}`);
      console.log(`     Stock después (movimiento): ${mov.stock_despues}`);
      console.log(`     Stock calculado anterior: ${stockAnterior}`);
      console.log(`     Stock calculado actual: ${stockCalculado}`);
      console.log(`     Referencia: ${mov.referencia}`);
      console.log(`     Fecha: ${mov.fecha_hora}`);
      console.log('');
    });

    console.log(`📊 Stock final calculado: ${stockCalculado}`);
    console.log(`📊 Stock actual en BD: ${stockActual.rows[0].stock_minimo}`);
    console.log(`📊 Diferencia: ${stockActual.rows[0].stock_minimo - stockCalculado}`);

    // 3. Verificar si hay movimientos que no se están contando
    console.log('\n🔍 Verificando movimientos por tipo:');
    const movimientosPorTipo = await pool.query(`
      SELECT 
        tipo_movimiento,
        COUNT(*) as cantidad_movimientos,
        SUM(cantidad) as cantidad_total
      FROM movimientos_stock
      WHERE articulo_id = $1
      GROUP BY tipo_movimiento
    `, [productoId]);

    let totalEntradas = 0;
    let totalSalidas = 0;
    
    movimientosPorTipo.rows.forEach(row => {
      console.log(`  - ${row.tipo_movimiento}: ${row.cantidad_movimientos} movimientos, ${row.cantidad_total} unidades total`);
      if (row.tipo_movimiento === 'entrada') {
        totalEntradas = row.cantidad_total;
      } else if (row.tipo_movimiento === 'salida') {
        totalSalidas = row.cantidad_total;
      }
    });

    console.log(`\n📊 Resumen:`);
    console.log(`  - Total entradas: ${totalEntradas}`);
    console.log(`  - Total salidas: ${totalSalidas}`);
    console.log(`  - Stock calculado: ${totalEntradas - totalSalidas}`);
    console.log(`  - Stock actual: ${stockActual.rows[0].stock_minimo}`);

  } catch (error) {
    console.error('❌ Error durante el debug:', error);
  } finally {
    await pool.end();
  }
}

debugStockCalculo();
