const pool = require('./config/database');

async function limpiarVentaAntigua() {
  try {
    console.log('🧹 Limpiando venta antigua sin detalles...\n');

    // 1. Verificar la venta problemática
    console.log('🔍 Verificando venta ID 14:');
    
    const ventaProblematica = await pool.query(`
      SELECT v.*, c.nombre as cliente_nombre
      FROM ventas v
      LEFT JOIN clientes c ON v.cliente_id = c.id
      WHERE v.id = 14
    `);
    
    if (ventaProblematica.rows.length > 0) {
      const venta = ventaProblematica.rows[0];
      console.log(`  - Venta ID: ${venta.id}`);
      console.log(`  - Fecha: ${venta.fecha}`);
      console.log(`  - Total: $${venta.total}`);
      console.log(`  - Cliente: ${venta.cliente_nombre}`);
      console.log(`  - Forma de pago: ${venta.forma_pago}`);
    } else {
      console.log('  - Venta ID 14 no encontrada');
      return;
    }

    // 2. Verificar si tiene detalles
    const detalles = await pool.query(`
      SELECT COUNT(*) as count
      FROM ventas_detalle
      WHERE venta_id = 14
    `);
    
    console.log(`  - Detalles encontrados: ${detalles.rows[0].count}`);

    // 3. Eliminar la venta si no tiene detalles
    if (detalles.rows[0].count == 0) {
      console.log('\n🗑️ Eliminando venta sin detalles...');
      
      const eliminacion = await pool.query(`
        DELETE FROM ventas
        WHERE id = 14
      `);
      
      console.log(`✅ Venta eliminada: ${eliminacion.rowCount} registros afectados`);
    } else {
      console.log('\n⚠️ La venta tiene detalles, no se eliminará');
    }

    // 4. Verificar estado final
    console.log('\n📊 Estado final:');
    
    const ventasCount = await pool.query('SELECT COUNT(*) as count FROM ventas');
    console.log(`  - Total ventas: ${ventasCount.rows[0].count}`);
    
    const ventasSinDetalles = await pool.query(`
      SELECT v.id, v.fecha, v.total
      FROM ventas v
      LEFT JOIN ventas_detalle vd ON v.id = vd.venta_id
      WHERE vd.venta_id IS NULL
    `);
    
    if (ventasSinDetalles.rows.length > 0) {
      console.log(`  ⚠️ Ventas sin detalles restantes: ${ventasSinDetalles.rows.length}`);
      ventasSinDetalles.rows.forEach(venta => {
        console.log(`    - Venta ${venta.id} (${venta.fecha}): $${venta.total}`);
      });
    } else {
      console.log('  ✅ Todas las ventas tienen detalles');
    }

    console.log('\n🎉 Limpieza completada!');

  } catch (error) {
    console.error('❌ Error en limpieza:', error);
  } finally {
    await pool.end();
  }
}

limpiarVentaAntigua(); 