require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testParticipantesCampania() {
  try {
    console.log('👥 Verificando participantes de campañas...\n');
    
    // 1. Verificar campañas existentes
    console.log('📋 Campañas existentes:');
    const campaniasResult = await pool.query(`
      SELECT id, nombre, activa, fecha_inicio, fecha_fin
      FROM fidelizacion_campanias
      ORDER BY creada_en DESC
    `);
    
    campaniasResult.rows.forEach(campania => {
      console.log(`  - ${campania.nombre} (ID: ${campania.id}, ${campania.activa ? 'Activa' : 'Inactiva'})`);
    });
    
    // 2. Verificar clientes con puntos por campaña
    console.log('\n🎯 Clientes con puntos por campaña:');
    const participantesResult = await pool.query(`
      SELECT 
        fc.nombre as campania,
        fc.activa,
        COUNT(fcl.cliente_id) as total_clientes,
        COUNT(CASE WHEN fcl.puntos_acumulados > 0 THEN 1 END) as clientes_con_puntos,
        COALESCE(SUM(fcl.puntos_acumulados), 0) as total_puntos
      FROM fidelizacion_campanias fc
      LEFT JOIN fidelizacion_clientes fcl ON fc.id = fcl.campania_id
      GROUP BY fc.id, fc.nombre, fc.activa
      ORDER BY fc.creada_en DESC
    `);
    
    participantesResult.rows.forEach(row => {
      console.log(`  - ${row.campania}:`);
      console.log(`    Total clientes registrados: ${row.total_clientes}`);
      console.log(`    Clientes con puntos: ${row.clientes_con_puntos}`);
      console.log(`    Total puntos: ${row.total_puntos}`);
    });
    
    // 3. Verificar clientes individuales con puntos
    console.log('\n👤 Detalle de clientes con puntos:');
    const clientesPuntosResult = await pool.query(`
      SELECT 
        fc.nombre as campania,
        c.nombre as cliente,
        fcl.puntos_acumulados,
        fcl.ultima_actualizacion
      FROM fidelizacion_clientes fcl
      JOIN fidelizacion_campanias fc ON fcl.campania_id = fc.id
      JOIN clientes c ON fcl.cliente_id = c.id
      WHERE fcl.puntos_acumulados > 0
      ORDER BY fc.nombre, fcl.puntos_acumulados DESC
    `);
    
    if (clientesPuntosResult.rows.length === 0) {
      console.log('  ❌ No hay clientes con puntos acumulados');
    } else {
      clientesPuntosResult.rows.forEach(row => {
        console.log(`  - ${row.campania} → ${row.cliente}: ${row.puntos_acumulados} puntos`);
      });
    }
    
    // 4. Verificar ventas recientes
    console.log('\n💰 Ventas recientes:');
    const ventasResult = await pool.query(`
      SELECT 
        v.id,
        v.cliente_id,
        v.total,
        v.fecha,
        c.nombre as cliente
      FROM ventas v
      JOIN clientes c ON v.cliente_id = c.id
      ORDER BY v.fecha DESC
      LIMIT 5
    `);
    
    ventasResult.rows.forEach(venta => {
      console.log(`  - Venta ${venta.id}: ${venta.cliente} - Gs ${venta.total} (${venta.fecha})`);
    });
    
    console.log('\n✅ Verificación completada');
    
  } catch (error) {
    console.error('❌ Error verificando participantes:', error);
  } finally {
    await pool.end();
  }
}

testParticipantesCampania(); 