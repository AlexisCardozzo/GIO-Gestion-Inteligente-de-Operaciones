const pool = require('./config/database');

async function verificarFormatoMovimientos() {
  try {
    console.log('🔍 Verificando formato de movimientos de stock...\n');

    // Verificar movimientos de venta
    const movimientosVentas = await pool.query(`
      SELECT 
        ms.id,
        ms.referencia,
        ms.tipo_movimiento,
        ms.cantidad,
        ms.fecha_hora,
        a.nombre as producto_nombre
      FROM movimientos_stock ms
      LEFT JOIN articulos a ON ms.articulo_id = a.id
      WHERE ms.referencia ILIKE '%venta%'
      ORDER BY ms.fecha_hora DESC
      LIMIT 10
    `);
    
    console.log('📊 Movimientos de venta encontrados:');
    movimientosVentas.rows.forEach(mov => {
      console.log(`  - ID ${mov.id}: ${mov.producto_nombre} x${mov.cantidad}`);
      console.log(`    Referencia: "${mov.referencia}"`);
      console.log(`    Tipo: ${mov.tipo_movimiento}`);
      console.log(`    Fecha: ${mov.fecha_hora}`);
      console.log('');
    });

    // Verificar si hay movimientos sin venta_id
    const movimientosSinVentaId = await pool.query(`
      SELECT COUNT(*) as count
      FROM movimientos_stock
      WHERE referencia ILIKE '%venta%' AND referencia NOT LIKE '%venta_id=%'
    `);
    
    console.log(`⚠️ Movimientos sin venta_id: ${movimientosSinVentaId.rows[0].count}`);

    // Extraer venta_ids únicos
    const ventaIds = new Set();
    movimientosVentas.rows.forEach(mov => {
      const ventaIdMatch = mov.referencia.match(/venta_id=(\d+)/);
      if (ventaIdMatch) {
        ventaIds.add(ventaIdMatch[1]);
      }
    });
    
    console.log(`\n📈 Ventas únicas encontradas: ${ventaIds.size}`);
    console.log('IDs de ventas:', Array.from(ventaIds).sort((a, b) => parseInt(a) - parseInt(b)));

    console.log('\n🎉 Verificación completada!');

  } catch (error) {
    console.error('❌ Error en verificación:', error);
  } finally {
    await pool.end();
  }
}

verificarFormatoMovimientos(); 