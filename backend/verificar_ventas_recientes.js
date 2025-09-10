const pool = require('./config/database');

async function verificarVentasRecientes() {
  try {
    console.log('📊 Ventas más recientes:');
    
    const ventas = await pool.query(`
      SELECT id, fecha, total, forma_pago
      FROM ventas 
      ORDER BY fecha DESC 
      LIMIT 10
    `);
    
    ventas.rows.forEach(venta => {
      console.log(`  - Venta ${venta.id}: ${venta.fecha} - $${venta.total} (${venta.forma_pago})`);
    });

    console.log('\n📊 Movimientos más recientes:');
    
    const movimientos = await pool.query(`
      SELECT id, fecha_hora, referencia, tipo_movimiento
      FROM movimientos_stock 
      WHERE referencia = 'venta'
      ORDER BY fecha_hora DESC 
      LIMIT 10
    `);
    
    movimientos.rows.forEach(mov => {
      console.log(`  - Movimiento ${mov.id}: ${mov.fecha_hora} - ${mov.referencia} (${mov.tipo_movimiento})`);
    });

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await pool.end();
  }
}

verificarVentasRecientes(); 