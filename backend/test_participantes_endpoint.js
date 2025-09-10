require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testParticipantesEndpoint() {
  try {
    console.log('🧪 Probando endpoint de participantes...\n');
    
    // 1. Verificar campañas existentes
    const campaniasResult = await pool.query(`
      SELECT id, nombre FROM fidelizacion_campanias WHERE activa = true
    `);
    
    if (campaniasResult.rows.length === 0) {
      console.log('❌ No hay campañas activas para probar');
      return;
    }
    
    const campania = campaniasResult.rows[0];
    console.log(`📋 Probando con campaña: ${campania.nombre} (ID: ${campania.id})`);
    
    // 2. Simular la consulta del endpoint
    const query = `
      SELECT 
        c.id,
        c.nombre,
        COALESCE(c.identificador, 'Sin CI/RUC') as ci_ruc,
        COALESCE(c.telefono, 'Sin celular') as celular,
        fcl.puntos_acumulados,
        fcl.ultima_actualizacion,
        COUNT(v.id) as total_ventas,
        COALESCE(SUM(v.total), 0) as total_gastado
      FROM fidelizacion_clientes fcl
      JOIN clientes c ON fcl.cliente_id = c.id
      LEFT JOIN ventas v ON c.id = v.cliente_id
      WHERE fcl.campania_id = $1 AND fcl.puntos_acumulados > 0
      GROUP BY c.id, c.nombre, c.identificador, c.telefono, fcl.puntos_acumulados, fcl.ultima_actualizacion
      ORDER BY fcl.puntos_acumulados DESC, c.nombre ASC
    `;
    
    const result = await pool.query(query, [campania.id]);
    
    console.log(`\n👥 Participantes encontrados: ${result.rows.length}`);
    
    if (result.rows.length > 0) {
      console.log('\n📊 Detalle de participantes:');
      result.rows.forEach((participante, index) => {
        console.log(`  ${index + 1}. ${participante.nombre}`);
        console.log(`     CI/RUC: ${participante.ci_ruc}`);
        console.log(`     Celular: ${participante.celular}`);
        console.log(`     Puntos: ${participante.puntos_acumulados}`);
        console.log(`     Ventas: ${participante.total_ventas}`);
        console.log(`     Total gastado: Gs ${participante.total_gastado}`);
        console.log('');
      });
    } else {
      console.log('❌ No hay participantes con puntos en esta campaña');
    }
    
    console.log('✅ Prueba del endpoint completada');
    
  } catch (error) {
    console.error('❌ Error probando endpoint:', error);
  } finally {
    await pool.end();
  }
}

testParticipantesEndpoint(); 