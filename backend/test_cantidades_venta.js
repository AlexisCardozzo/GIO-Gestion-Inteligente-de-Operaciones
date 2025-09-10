const pool = require('./config/database');

async function testCantidadesVenta() {
  try {
    console.log('🧪 Probando cantidades en ventas...\n');

    // 1. Verificar estructura de ventas_detalle
    console.log('📋 Verificando estructura de ventas_detalle:');
    const estructura = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'ventas_detalle'
      ORDER BY ordinal_position
    `);
    
    estructura.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    // 2. Verificar las últimas ventas con detalles
    console.log('\n📊 Últimas ventas con detalles:');
    const ventasDetalle = await pool.query(`
      SELECT 
        v.id as venta_id,
        v.total as total_venta,
        vd.producto_id,
        vd.cantidad,
        vd.precio_unitario,
        vd.subtotal,
        a.nombre as producto_nombre,
        a.precio_venta as precio_original
      FROM ventas v
      LEFT JOIN ventas_detalle vd ON v.id = vd.venta_id
      LEFT JOIN articulos a ON vd.producto_id = a.id
      ORDER BY v.fecha DESC
      LIMIT 10
    `);

    let ventaActual = null;
    ventasDetalle.rows.forEach((row, index) => {
      if (row.venta_id !== ventaActual) {
        if (ventaActual !== null) console.log('');
        console.log(`  Venta ${row.venta_id} - Total: $${row.total_venta}`);
        ventaActual = row.venta_id;
      }
      
      if (row.producto_id) {
        const subtotalCalculado = row.cantidad * row.precio_unitario;
        const coincide = Math.abs(subtotalCalculado - row.subtotal) < 0.01;
        console.log(`    - ${row.producto_nombre}: ${row.cantidad} x $${row.precio_unitario} = $${row.subtotal} ${coincide ? '✅' : '❌ (debería ser $' + subtotalCalculado + ')'}`);
      }
    });

    // 3. Verificar si hay duplicados o problemas en ventas_detalle
    console.log('\n🔍 Verificando posibles duplicados:');
    const duplicados = await pool.query(`
      SELECT 
        venta_id,
        producto_id,
        COUNT(*) as cantidad_registros,
        SUM(cantidad) as cantidad_total,
        SUM(subtotal) as subtotal_total
      FROM ventas_detalle
      GROUP BY venta_id, producto_id
      HAVING COUNT(*) > 1
      ORDER BY venta_id DESC
    `);

    if (duplicados.rows.length > 0) {
      console.log('❌ Encontrados registros duplicados:');
      duplicados.rows.forEach(row => {
        console.log(`  - Venta ${row.venta_id}, Producto ${row.producto_id}: ${row.cantidad_registros} registros, ${row.cantidad_total} unidades, $${row.subtotal_total}`);
      });
    } else {
      console.log('✅ No se encontraron registros duplicados');
    }

    // 4. Verificar consistencia de datos
    console.log('\n🔍 Verificando consistencia de datos:');
    const inconsistencias = await pool.query(`
      SELECT 
        vd.venta_id,
        vd.producto_id,
        vd.cantidad,
        vd.precio_unitario,
        vd.subtotal,
        (vd.cantidad * vd.precio_unitario) as subtotal_calculado,
        ABS(vd.subtotal - (vd.cantidad * vd.precio_unitario)) as diferencia
      FROM ventas_detalle vd
      WHERE ABS(vd.subtotal - (vd.cantidad * vd.precio_unitario)) > 0.01
      ORDER BY vd.venta_id DESC
      LIMIT 5
    `);

    if (inconsistencias.rows.length > 0) {
      console.log('❌ Encontradas inconsistencias en subtotales:');
      inconsistencias.rows.forEach(row => {
        console.log(`  - Venta ${row.venta_id}, Producto ${row.producto_id}: ${row.cantidad} x $${row.precio_unitario} = $${row.subtotal} (debería ser $${row.subtotal_calculado})`);
      });
    } else {
      console.log('✅ Todos los subtotales son consistentes');
    }

  } catch (error) {
    console.error('❌ Error durante la prueba:', error);
  } finally {
    await pool.end();
  }
}

testCantidadesVenta();
