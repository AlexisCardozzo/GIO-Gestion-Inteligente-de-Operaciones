require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testClientesFieles() {
  try {
    console.log('👥 Probando consulta de clientes fieles...\n');
    
    // Usar la misma consulta que el endpoint
    const query = `
      SELECT 
        c.id,
        c.nombre,
        COALESCE(c.ci_ruc, 'N/A') as ci_ruc,
        COALESCE(c.celular, 'N/A') as celular,
        COUNT(v.id) as total_compras,
        COALESCE(SUM(v.total), 0) as total_gastado,
        MAX(v.fecha) as ultima_compra,
        MIN(v.fecha) as primera_compra,
        COALESCE(SUM(fcl.puntos_acumulados), 0) as puntos_fidelizacion,
        CASE 
          WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 100 THEN 'PLATINO'
          WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 50 THEN 'ORO'
          WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 20 THEN 'PLATA'
          ELSE 'BRONCE'
        END as nivel_fidelidad
      FROM clientes c
      LEFT JOIN ventas v ON c.id = v.cliente_id
      LEFT JOIN fidelizacion_clientes fcl ON c.id = fcl.cliente_id
      WHERE c.activo = true OR c.activo IS NULL
      GROUP BY c.id, c.nombre, c.ci_ruc, c.celular
      HAVING COUNT(v.id) > 0
      ORDER BY total_gastado DESC, total_compras DESC
      LIMIT 100
    `;
    
    const result = await pool.query(query);
    
    console.log(`✅ Clientes fieles obtenidos: ${result.rows.length}\n`);
    
    result.rows.forEach((cliente, index) => {
      console.log(`  ${index + 1}. ${cliente.nombre} (${cliente.ci_ruc})`);
      console.log(`     Compras: ${cliente.total_compras}`);
      console.log(`     Total gastado: Gs ${cliente.total_gastado}`);
      console.log(`     Puntos: ${cliente.puntos_fidelizacion}`);
      console.log(`     Nivel: ${cliente.nivel_fidelidad}`);
      console.log('');
    });
    
    // Verificar distribución de niveles
    const niveles = result.rows.reduce((acc, cliente) => {
      acc[cliente.nivel_fidelidad] = (acc[cliente.nivel_fidelidad] || 0) + 1;
      return acc;
    }, {});
    
    console.log('📊 Distribución de niveles:');
    Object.entries(niveles).forEach(([nivel, cantidad]) => {
      console.log(`  ${nivel}: ${cantidad} clientes`);
    });
    
    console.log('\n✅ Prueba completada');
    
  } catch (error) {
    console.error('❌ Error en prueba:', error);
  } finally {
    await pool.end();
  }
}

testClientesFieles(); 