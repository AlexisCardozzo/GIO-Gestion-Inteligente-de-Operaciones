require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testNivelesFidelidad() {
  try {
    console.log('🏆 Probando niveles de fidelidad...\n');
    
    // 1. Verificar clientes con sus datos actuales
    console.log('👥 Clientes con sus datos de fidelidad:');
    const clientesResult = await pool.query(`
      SELECT 
        c.id,
        c.nombre,
        COALESCE(c.ci_ruc, 'N/A') as ci_ruc,
        COUNT(v.id) as total_compras,
        COALESCE(SUM(v.total), 0) as total_gastado,
        COALESCE(SUM(fcl.puntos_acumulados), 0) as puntos_fidelizacion,
        CASE 
          WHEN COUNT(v.id) >= 10 AND COALESCE(SUM(v.total), 0) >= 1000000 THEN 'PLATINO'
          WHEN COUNT(v.id) >= 5 AND COALESCE(SUM(v.total), 0) >= 500000 THEN 'ORO'
          WHEN COUNT(v.id) >= 3 AND COALESCE(SUM(v.total), 0) >= 200000 THEN 'PLATA'
          ELSE 'BRONCE'
        END as nivel_actual,
        CASE 
          WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 100 THEN 'PLATINO'
          WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 50 THEN 'ORO'
          WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 20 THEN 'PLATA'
          ELSE 'BRONCE'
        END as nivel_por_puntos
      FROM clientes c
      LEFT JOIN ventas v ON c.id = v.cliente_id
      LEFT JOIN fidelizacion_clientes fcl ON c.id = fcl.cliente_id
      WHERE c.activo = true OR c.activo IS NULL
      GROUP BY c.id, c.nombre, c.ci_ruc
      HAVING COUNT(v.id) > 0
      ORDER BY total_gastado DESC, total_compras DESC
    `);
    
    clientesResult.rows.forEach((cliente, index) => {
      console.log(`  ${index + 1}. ${cliente.nombre} (${cliente.ci_ruc})`);
      console.log(`     Compras: ${cliente.total_compras}`);
      console.log(`     Total gastado: Gs ${cliente.total_gastado.toLocaleString()}`);
      console.log(`     Puntos: ${cliente.puntos_fidelizacion}`);
      console.log(`     Nivel actual: ${cliente.nivel_actual}`);
      console.log(`     Nivel por puntos: ${cliente.nivel_por_puntos}`);
      console.log('');
    });
    
    // 2. Proponer nuevos criterios basados en puntos
    console.log('📊 Propuesta de nuevos criterios por puntos:');
    console.log('  BRONCE: 0-19 puntos');
    console.log('  PLATA: 20-49 puntos');
    console.log('  ORO: 50-99 puntos');
    console.log('  PLATINO: 100+ puntos');
    console.log('');
    
    // 3. Mostrar distribución con nuevos criterios
    console.log('📈 Distribución con nuevos criterios:');
    const bronce = clientesResult.rows.filter(c => c.puntos_fidelizacion < 20).length;
    const plata = clientesResult.rows.filter(c => c.puntos_fidelizacion >= 20 && c.puntos_fidelizacion < 50).length;
    const oro = clientesResult.rows.filter(c => c.puntos_fidelizacion >= 50 && c.puntos_fidelizacion < 100).length;
    const platino = clientesResult.rows.filter(c => c.puntos_fidelizacion >= 100).length;
    
    console.log(`  BRONCE: ${bronce} clientes`);
    console.log(`  PLATA: ${plata} clientes`);
    console.log(`  ORO: ${oro} clientes`);
    console.log(`  PLATINO: ${platino} clientes`);
    
    console.log('\n✅ Análisis de niveles completado');
    
  } catch (error) {
    console.error('❌ Error en análisis:', error);
  } finally {
    await pool.end();
  }
}

testNivelesFidelidad(); 