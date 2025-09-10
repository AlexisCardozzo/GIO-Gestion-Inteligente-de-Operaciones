const pool = require('./config/database');

async function verificarMovimientosProducto() {
  try {
    console.log('🔍 Verificando movimientos de producto específico...\n');

    // Verificar movimientos del producto pizza (ID: 1)
    const productoId = 1;
    
    console.log('📊 Todos los movimientos del producto pizza (ID: 1):');
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

    let stockCalculado = 0;
    movimientos.rows.forEach((mov, index) => {
      const cambio = mov.tipo_movimiento === 'entrada' ? mov.cantidad : -mov.cantidad;
      stockCalculado += cambio;
      console.log(`  ${index + 1}. ${mov.tipo_movimiento.toUpperCase()}: ${mov.cantidad} unidades`);
      console.log(`     Stock: ${mov.stock_antes} → ${mov.stock_despues} (calculado: ${stockCalculado})`);
      console.log(`     Referencia: ${mov.referencia}`);
      console.log(`     Fecha: ${mov.fecha_hora}`);
      console.log('');
    });

    // Verificar stock actual
    const stockActual = await pool.query('SELECT stock_minimo FROM articulos WHERE id = $1', [productoId]);
    console.log(`📊 Stock actual en la base de datos: ${stockActual.rows[0].stock_minimo}`);
    console.log(`📊 Stock calculado desde movimientos: ${stockCalculado}`);

    // Verificar si hay movimientos que no se están contando
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

    movimientosPorTipo.rows.forEach(row => {
      console.log(`  - ${row.tipo_movimiento}: ${row.cantidad_movimientos} movimientos, ${row.cantidad_total} unidades total`);
    });

    // Verificar si hay movimientos con referencias específicas
    console.log('\n🔍 Verificando movimientos por referencia:');
    const movimientosPorReferencia = await pool.query(`
      SELECT 
        referencia,
        COUNT(*) as cantidad_movimientos,
        SUM(cantidad) as cantidad_total
      FROM movimientos_stock
      WHERE articulo_id = $1
      GROUP BY referencia
      ORDER BY referencia
    `, [productoId]);

    movimientosPorReferencia.rows.forEach(row => {
      console.log(`  - ${row.referencia || 'Sin referencia'}: ${row.cantidad_movimientos} movimientos, ${row.cantidad_total} unidades total`);
    });

  } catch (error) {
    console.error('❌ Error durante la verificación:', error);
  } finally {
    await pool.end();
  }
}

verificarMovimientosProducto();
