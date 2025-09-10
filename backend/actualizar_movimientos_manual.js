const pool = require('./config/database');

async function actualizarMovimientosManual() {
  try {
    console.log('🔄 Actualizando movimientos manualmente...\n');

    // Mapeo de movimientos a ventas basado en las fechas
    const mapeo = [
      { movimiento: 19, venta: 38 },
      { movimiento: 18, venta: 37 },
      { movimiento: 17, venta: 36 },
      { movimiento: 16, venta: 35 },
      { movimiento: 15, venta: 34 },
      { movimiento: 14, venta: 33 },
      { movimiento: 13, venta: 32 },
      { movimiento: 12, venta: 31 },
      { movimiento: 11, venta: 30 },
      { movimiento: 10, venta: 29 },
    ];

    for (const item of mapeo) {
      await pool.query(`
        UPDATE movimientos_stock 
        SET referencia = $1
        WHERE id = $2
      `, [`venta_id=${item.venta}`, item.movimiento]);
      
      console.log(`✅ Movimiento ${item.movimiento} → Venta ${item.venta}`);
    }

    // Verificar resultado
    console.log('\n📊 Verificación final:');
    
    const movimientosActualizados = await pool.query(`
      SELECT 
        ms.id,
        ms.referencia,
        ms.fecha_hora,
        a.nombre as producto_nombre
      FROM movimientos_stock ms
      LEFT JOIN articulos a ON ms.articulo_id = a.id
      WHERE ms.referencia LIKE 'venta_id=%'
      ORDER BY ms.fecha_hora DESC
      LIMIT 10
    `);
    
    console.log(`Movimientos con venta_id: ${movimientosActualizados.rows.length}`);
    movimientosActualizados.rows.forEach(mov => {
      console.log(`  - ID ${mov.id}: ${mov.producto_nombre} - ${mov.referencia}`);
    });

    // Contar ventas únicas
    const ventaIds = new Set();
    const todosMovimientos = await pool.query(`
      SELECT referencia
      FROM movimientos_stock
      WHERE referencia LIKE 'venta_id=%'
    `);
    
    todosMovimientos.rows.forEach(mov => {
      const ventaIdMatch = mov.referencia.match(/venta_id=(\d+)/);
      if (ventaIdMatch) {
        ventaIds.add(ventaIdMatch[1]);
      }
    });
    
    console.log(`\n📈 Ventas únicas encontradas: ${ventaIds.size}`);
    console.log('IDs de ventas:', Array.from(ventaIds).sort((a, b) => parseInt(a) - parseInt(b)));

    console.log('\n🎉 Actualización completada!');

  } catch (error) {
    console.error('❌ Error en actualización:', error);
  } finally {
    await pool.end();
  }
}

actualizarMovimientosManual(); 