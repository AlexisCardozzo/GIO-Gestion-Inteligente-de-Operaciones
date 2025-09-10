const pool = require('./config/database');

async function diagnosticoControlVentas() {
  try {
    console.log('🔍 Diagnóstico completo del control de ventas...\n');

    // 1. Verificar estructura de tablas
    console.log('📋 Estructura de tablas:');
    
    const tablas = ['ventas', 'ventas_detalle', 'articulos'];
    
    for (const tabla of tablas) {
      try {
        const estructura = await pool.query(`
          SELECT column_name, data_type, is_nullable
          FROM information_schema.columns 
          WHERE table_name = $1
          ORDER BY ordinal_position
        `, [tabla]);
        
        console.log(`\n${tabla}:`);
        estructura.rows.forEach(col => {
          console.log(`  - ${col.column_name}: ${col.data_type} (${col.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
        });
      } catch (error) {
        console.log(`\n${tabla}: Error - ${error.message}`);
      }
    }

    // 2. Verificar datos de ventas
    console.log('\n📊 Datos de ventas:');
    
    const ventasCount = await pool.query('SELECT COUNT(*) as count FROM ventas');
    console.log(`  - Total ventas: ${ventasCount.rows[0].count}`);
    
    const ventasDetalleCount = await pool.query('SELECT COUNT(*) as count FROM ventas_detalle');
    console.log(`  - Total detalles: ${ventasDetalleCount.rows[0].count}`);
    
    const articulosCount = await pool.query('SELECT COUNT(*) as count FROM articulos WHERE activo = true');
    console.log(`  - Total artículos activos: ${articulosCount.rows[0].count}`);

    // 3. Verificar últimas ventas con detalles
    console.log('\n🛒 Últimas 5 ventas con detalles:');
    
    const ultimasVentas = await pool.query(`
      SELECT 
        v.id,
        v.fecha,
        v.total,
        v.forma_pago,
        c.nombre as cliente_nombre,
        COUNT(vd.id) as total_detalles,
        SUM(vd.subtotal) as total_calculado
      FROM ventas v
      LEFT JOIN clientes c ON v.cliente_id = c.id
      LEFT JOIN ventas_detalle vd ON v.id = vd.venta_id
      GROUP BY v.id, v.fecha, v.total, v.forma_pago, c.nombre
      ORDER BY v.fecha DESC
      LIMIT 5
    `);
    
    ultimasVentas.rows.forEach(venta => {
      console.log(`  - Venta ${venta.id}: $${venta.total} (${venta.forma_pago}) - Cliente: ${venta.cliente_nombre}`);
      console.log(`    Detalles: ${venta.total_detalles} | Total calculado: $${venta.total_calculado || 0}`);
    });

    // 4. Verificar cálculos de ganancia
    console.log('\n💰 Cálculos de ganancia:');
    
    const gananciaQuery = await pool.query(`
      SELECT 
        v.id as venta_id,
        v.total as total_venta,
        SUM(vd.subtotal) as total_detalles,
        SUM((vd.precio_unitario - COALESCE(a.precio_compra, 0)) * vd.cantidad) as ganancia_calculada
      FROM ventas v
      LEFT JOIN ventas_detalle vd ON v.id = vd.venta_id
      LEFT JOIN articulos a ON vd.producto_id = a.id
      GROUP BY v.id, v.total
      ORDER BY v.fecha DESC
      LIMIT 5
    `);
    
    gananciaQuery.rows.forEach(row => {
      console.log(`  - Venta ${row.venta_id}:`);
      console.log(`    Total venta: $${row.total_venta}`);
      console.log(`    Total detalles: $${row.total_detalles || 0}`);
      console.log(`    Ganancia calculada: $${row.ganancia_calculada || 0}`);
    });

    // 5. Verificar totales generales
    console.log('\n📈 Totales generales:');
    
    const totalesGenerales = await pool.query(`
      SELECT 
        COUNT(*) as total_ventas,
        COALESCE(SUM(total), 0) as monto_total,
        COALESCE(AVG(total), 0) as promedio_venta,
        COUNT(DISTINCT cliente_id) as clientes_unicos
      FROM ventas
    `);
    
    const totales = totalesGenerales.rows[0];
    console.log(`  - Total ventas: ${totales.total_ventas}`);
    console.log(`  - Monto total: $${totales.monto_total}`);
    console.log(`  - Promedio por venta: $${totales.promedio_venta}`);
    console.log(`  - Clientes únicos: ${totales.clientes_unicos}`);

    // 6. Verificar problemas específicos
    console.log('\n⚠️ Problemas identificados:');
    
    // Ventas sin detalles
    const ventasSinDetalles = await pool.query(`
      SELECT v.id, v.fecha, v.total
      FROM ventas v
      LEFT JOIN ventas_detalle vd ON v.id = vd.venta_id
      WHERE vd.venta_id IS NULL
    `);
    
    if (ventasSinDetalles.rows.length > 0) {
      console.log(`  ❌ Ventas sin detalles: ${ventasSinDetalles.rows.length}`);
      ventasSinDetalles.rows.forEach(venta => {
        console.log(`    - Venta ${venta.id} (${venta.fecha}): $${venta.total}`);
      });
    } else {
      console.log('  ✅ Todas las ventas tienen detalles');
    }

    // Inconsistencias en totales
    const inconsistencias = await pool.query(`
      SELECT 
        v.id,
        v.total as total_venta,
        SUM(vd.subtotal) as total_detalles
      FROM ventas v
      LEFT JOIN ventas_detalle vd ON v.id = vd.venta_id
      GROUP BY v.id, v.total
      HAVING ABS(v.total - COALESCE(SUM(vd.subtotal), 0)) > 0.01
    `);
    
    if (inconsistencias.rows.length > 0) {
      console.log(`  ❌ Inconsistencias en totales: ${inconsistencias.rows.length}`);
      inconsistencias.rows.forEach(inconsistencia => {
        console.log(`    - Venta ${inconsistencia.id}: Venta=${inconsistencia.total_venta}, Detalles=${inconsistencia.total_detalles}`);
      });
    } else {
      console.log('  ✅ Todos los totales son consistentes');
    }

    // 7. Verificar endpoints del backend
    console.log('\n🔗 Verificación de endpoints:');
    
    const endpoints = [
      { nombre: 'Total ventas', query: 'SELECT COUNT(*) as total FROM ventas' },
      { nombre: 'Resumen ventas', query: `
        SELECT 
          COUNT(*) as total_ventas,
          COALESCE(SUM(total), 0) as monto_total,
          COALESCE(AVG(total), 0) as promedio_venta
        FROM ventas
      `},
      { nombre: 'Lista ventas', query: `
        SELECT v.id, v.fecha, v.total, c.nombre as cliente
        FROM ventas v
        LEFT JOIN clientes c ON v.cliente_id = c.id
        ORDER BY v.fecha DESC
        LIMIT 5
      `}
    ];
    
    for (const endpoint of endpoints) {
      try {
        const result = await pool.query(endpoint.query);
        console.log(`  ✅ ${endpoint.nombre}: ${result.rows.length} registros`);
      } catch (error) {
        console.log(`  ❌ ${endpoint.nombre}: Error - ${error.message}`);
      }
    }

    console.log('\n🎉 Diagnóstico completado!');
    console.log('💡 Revisa los problemas identificados arriba');

  } catch (error) {
    console.error('❌ Error en diagnóstico:', error);
  } finally {
    await pool.end();
  }
}

diagnosticoControlVentas(); 