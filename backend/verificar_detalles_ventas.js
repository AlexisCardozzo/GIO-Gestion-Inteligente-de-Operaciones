const pool = require('./config/database');

async function verificarDetallesVentas() {
  try {
    console.log('🔍 Verificando detalles de ventas...\n');

    // 1. Verificar estructura de la tabla
    console.log('📋 Estructura de la tabla ventas_detalle:');
    const estructura = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'ventas_detalle'
      ORDER BY ordinal_position
    `);
    
    estructura.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    // 2. Verificar todas las ventas
    console.log('\n📊 Todas las ventas:');
    const todasLasVentas = await pool.query(`
      SELECT id, fecha, total, forma_pago
      FROM ventas
      ORDER BY id
    `);
    
    todasLasVentas.rows.forEach(venta => {
      console.log(`  - Venta ${venta.id}: $${venta.total} (${venta.forma_pago}) - ${venta.fecha}`);
    });

    // 3. Verificar detalles de cada venta
    console.log('\n📦 Detalles de cada venta:');
    for (const venta of todasLasVentas.rows) {
      const detalles = await pool.query(`
        SELECT 
          dv.id,
          dv.venta_id,
          dv.producto_id,
          dv.cantidad,
          dv.precio_unitario,
          a.nombre as producto_nombre
        FROM ventas_detalle dv
        LEFT JOIN articulos a ON dv.producto_id = a.id
        WHERE dv.venta_id = $1
      `, [venta.id]);

      if (detalles.rows.length === 0) {
        console.log(`  ❌ Venta ${venta.id}: Sin detalles`);
      } else {
        console.log(`  ✅ Venta ${venta.id}: ${detalles.rows.length} detalles`);
        detalles.rows.forEach(detalle => {
          console.log(`    - ${detalle.producto_nombre} (ID: ${detalle.producto_id}): ${detalle.cantidad} x $${detalle.precio_unitario}`);
        });
      }
    }

    // 4. Verificar si hay detalles huérfanos
    console.log('\n🔍 Verificando detalles huérfanos:');
    const detallesHuerfanos = await pool.query(`
      SELECT dv.id, dv.venta_id, dv.producto_id, dv.cantidad
      FROM ventas_detalle dv
      LEFT JOIN ventas v ON dv.venta_id = v.id
      WHERE v.id IS NULL
    `);

    if (detallesHuerfanos.rows.length > 0) {
      console.log(`❌ Encontrados ${detallesHuerfanos.rows.length} detalles huérfanos:`);
      detallesHuerfanos.rows.forEach(detalle => {
        console.log(`  - Detalle ${detalle.id}: venta_id=${detalle.venta_id}, producto_id=${detalle.producto_id}`);
      });
    } else {
      console.log('✅ No hay detalles huérfanos');
    }

    // 5. Verificar productos en detalles
    console.log('\n📦 Productos en detalles:');
    const productosEnDetalles = await pool.query(`
      SELECT 
        dv.producto_id,
        a.nombre as producto_nombre,
        COUNT(*) as cantidad_detalles,
        SUM(dv.cantidad) as cantidad_total_vendida
      FROM ventas_detalle dv
      LEFT JOIN articulos a ON dv.producto_id = a.id
      GROUP BY dv.producto_id, a.nombre
      ORDER BY cantidad_total_vendida DESC
    `);

    productosEnDetalles.rows.forEach(producto => {
      console.log(`  - ${producto.producto_nombre} (ID: ${producto.producto_id}):`);
      console.log(`    ${producto.cantidad_detalles} detalles, ${producto.cantidad_total_vendida} unidades vendidas`);
    });

    // 6. Resumen final
    console.log('\n📈 Resumen final:');
    const totalVentas = await pool.query('SELECT COUNT(*) as total FROM ventas');
    const totalDetalles = await pool.query('SELECT COUNT(*) as total FROM ventas_detalle');
    const ventasConDetalles = await pool.query(`
      SELECT COUNT(DISTINCT v.id) as total
      FROM ventas v
      INNER JOIN ventas_detalle dv ON v.id = dv.venta_id
    `);
    
    console.log(`  - Total ventas: ${totalVentas.rows[0].total}`);
    console.log(`  - Total detalles: ${totalDetalles.rows[0].total}`);
    console.log(`  - Ventas con detalles: ${ventasConDetalles.rows[0].total}`);
    console.log(`  - Ventas sin detalles: ${totalVentas.rows[0].total - ventasConDetalles.rows[0].total}`);

  } catch (error) {
    console.error('❌ Error durante la verificación:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar la verificación
verificarDetallesVentas();
