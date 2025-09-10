const pool = require('./config/database');

async function actualizarMovimientosVentaId() {
  try {
    console.log('🔄 Actualizando movimientos de stock con venta_id...\n');

    // 1. Verificar movimientos actuales
    console.log('📊 Movimientos actuales:');
    
    const movimientosActuales = await pool.query(`
      SELECT 
        ms.id,
        ms.referencia,
        ms.fecha_hora,
        ms.articulo_id,
        a.nombre as producto_nombre
      FROM movimientos_stock ms
      LEFT JOIN articulos a ON ms.articulo_id = a.id
      WHERE ms.referencia = 'venta'
      ORDER BY ms.fecha_hora DESC
      LIMIT 5
    `);
    
    console.log(`Movimientos con referencia 'venta': ${movimientosActuales.rows.length}`);
    movimientosActuales.rows.forEach(mov => {
      console.log(`  - ID ${mov.id}: ${mov.producto_nombre} (${mov.fecha_hora})`);
    });

    // 2. Buscar ventas correspondientes por fecha
    console.log('\n🔍 Buscando ventas correspondientes...');
    
    for (const mov of movimientosActuales.rows) {
      const fechaMov = new Date(mov.fecha_hora);
      const fechaInicio = new Date(fechaMov.getTime() - 60000); // 1 minuto antes
      const fechaFin = new Date(fechaMov.getTime() + 60000); // 1 minuto después
      
      const ventaCorrespondiente = await pool.query(`
        SELECT v.id, v.fecha, v.total
        FROM ventas v
        WHERE v.fecha BETWEEN $1 AND $2
        ORDER BY ABS(EXTRACT(EPOCH FROM (v.fecha - $3)))
        LIMIT 1
      `, [fechaInicio, fechaFin, fechaMov]);
      
      if (ventaCorrespondiente.rows.length > 0) {
        const venta = ventaCorrespondiente.rows[0];
        console.log(`  - Movimiento ${mov.id} → Venta ${venta.id} (${venta.fecha})`);
        
        // Actualizar la referencia
        await pool.query(`
          UPDATE movimientos_stock 
          SET referencia = $1
          WHERE id = $2
        `, [`venta_id=${venta.id}`, mov.id]);
        
        console.log(`    ✅ Actualizado: venta_id=${venta.id}`);
      } else {
        console.log(`  - Movimiento ${mov.id}: No se encontró venta correspondiente`);
      }
    }

    // 3. Verificar resultado
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
      LIMIT 5
    `);
    
    console.log(`Movimientos con venta_id: ${movimientosActualizados.rows.length}`);
    movimientosActualizados.rows.forEach(mov => {
      console.log(`  - ID ${mov.id}: ${mov.producto_nombre} - ${mov.referencia}`);
    });

    // 4. Contar ventas únicas
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

actualizarMovimientosVentaId(); 