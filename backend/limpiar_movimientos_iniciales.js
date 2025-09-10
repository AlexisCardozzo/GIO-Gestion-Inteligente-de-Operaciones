const pool = require('./config/database');

async function limpiarMovimientosIniciales() {
  try {
    console.log('🧹 Limpiando movimientos de carga inicial...\n');

    // 1. Verificar movimientos de carga inicial
    console.log('📊 Movimientos de carga inicial encontrados:');
    const movimientosIniciales = await pool.query(`
      SELECT 
        ms.id,
        ms.articulo_id,
        a.nombre as producto_nombre,
        ms.cantidad,
        ms.stock_antes,
        ms.stock_despues
      FROM movimientos_stock ms
      LEFT JOIN articulos a ON ms.articulo_id = a.id
      WHERE ms.referencia = 'Carga inicial'
      ORDER BY ms.articulo_id
    `);

    if (movimientosIniciales.rows.length === 0) {
      console.log('✅ No hay movimientos de carga inicial para limpiar');
      return;
    }

    movimientosIniciales.rows.forEach(mov => {
      console.log(`  - ${mov.producto_nombre} (ID: ${mov.articulo_id}): ${mov.cantidad} unidades`);
    });

    // 2. Eliminar movimientos de carga inicial
    console.log('\n🗑️ Eliminando movimientos de carga inicial...');
    const eliminados = await pool.query(`
      DELETE FROM movimientos_stock 
      WHERE referencia = 'Carga inicial'
    `);

    console.log(`✅ Eliminados ${eliminados.rowCount} movimientos de carga inicial`);

    // 3. Recalcular stock basado en movimientos restantes
    console.log('\n🔄 Recalculando stock...');
    const productos = await pool.query(`
      SELECT id, nombre, stock_minimo
      FROM articulos
      ORDER BY id
    `);

    for (const producto of productos.rows) {
      // Calcular stock basado en movimientos
      const movimientos = await pool.query(`
        SELECT 
          SUM(CASE WHEN tipo_movimiento = 'entrada' THEN cantidad ELSE 0 END) as total_entradas,
          SUM(CASE WHEN tipo_movimiento = 'salida' THEN cantidad ELSE 0 END) as total_salidas
        FROM movimientos_stock
        WHERE articulo_id = $1
      `, [producto.id]);

      const totalEntradas = parseInt(movimientos.rows[0].total_entradas) || 0;
      const totalSalidas = parseInt(movimientos.rows[0].total_salidas) || 0;
      const stockCalculado = totalEntradas - totalSalidas;

      // Actualizar stock si es diferente
      if (stockCalculado !== producto.stock_minimo) {
        await pool.query(`
          UPDATE articulos 
          SET stock_minimo = $1 
          WHERE id = $2
        `, [stockCalculado, producto.id]);

        console.log(`  - ${producto.nombre}: ${producto.stock_minimo} → ${stockCalculado}`);
      }
    }

    console.log('\n✅ Limpieza completada exitosamente!');

  } catch (error) {
    console.error('❌ Error durante la limpieza:', error);
  } finally {
    await pool.end();
  }
}

limpiarMovimientosIniciales();
