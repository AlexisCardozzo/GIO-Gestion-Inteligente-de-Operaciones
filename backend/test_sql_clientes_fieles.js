require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testSqlClientesFieles() {
  try {
    console.log('🔍 Probando consulta SQL de clientes fieles...\n');
    
    // Consulta original que está causando error
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
        COALESCE(fcl.puntos_acumulados, 0) as puntos_fidelizacion,
        CASE 
          WHEN COALESCE(fcl.puntos_acumulados, 0) >= 100 THEN 'PLATINO'
          WHEN COALESCE(fcl.puntos_acumulados, 0) >= 50 THEN 'ORO'
          WHEN COALESCE(fcl.puntos_acumulados, 0) >= 20 THEN 'PLATA'
          ELSE 'BRONCE'
        END as nivel_fidelidad
      FROM clientes c
      LEFT JOIN ventas v ON c.id = v.cliente_id
      LEFT JOIN (
        SELECT 
          cliente_id,
          SUM(puntos_acumulados) as puntos_acumulados
        FROM fidelizacion_clientes
        GROUP BY cliente_id
      ) fcl ON c.id = fcl.cliente_id
      WHERE c.activo = true OR c.activo IS NULL
      GROUP BY c.id, c.nombre, c.ci_ruc, c.celular
      HAVING COUNT(v.id) > 0
      ORDER BY total_gastado DESC, total_compras DESC
      LIMIT 100
    `;
    
    console.log('1️⃣ Probando consulta original...');
    try {
      const result = await pool.query(query);
      console.log(`   ✅ Consulta exitosa: ${result.rows.length} filas`);
      result.rows.forEach((row, index) => {
        console.log(`   ${index + 1}. ${row.nombre}: ${row.puntos_fidelizacion} puntos → ${row.nivel_fidelidad}`);
      });
    } catch (error) {
      console.log(`   ❌ Error en consulta original: ${error.message}`);
      
      // Probar consulta corregida
      console.log('\n2️⃣ Probando consulta corregida...');
      const queryCorregida = `
        SELECT 
          c.id,
          c.nombre,
          COALESCE(c.ci_ruc, 'N/A') as ci_ruc,
          COALESCE(c.celular, 'N/A') as celular,
          COUNT(v.id) as total_compras,
          COALESCE(SUM(v.total), 0) as total_gastado,
          MAX(v.fecha) as ultima_compra,
          MIN(v.fecha) as primera_compra,
          COALESCE(fcl.puntos_acumulados, 0) as puntos_fidelizacion,
          CASE 
            WHEN COALESCE(fcl.puntos_acumulados, 0) >= 100 THEN 'PLATINO'
            WHEN COALESCE(fcl.puntos_acumulados, 0) >= 50 THEN 'ORO'
            WHEN COALESCE(fcl.puntos_acumulados, 0) >= 20 THEN 'PLATA'
            ELSE 'BRONCE'
          END as nivel_fidelidad
        FROM clientes c
        LEFT JOIN ventas v ON c.id = v.cliente_id
        LEFT JOIN (
          SELECT 
            cliente_id,
            SUM(puntos_acumulados) as puntos_acumulados
          FROM fidelizacion_clientes
          GROUP BY cliente_id
        ) fcl ON c.id = fcl.cliente_id
        WHERE c.activo = true OR c.activo IS NULL
        GROUP BY c.id, c.nombre, c.ci_ruc, c.celular, fcl.puntos_acumulados
        HAVING COUNT(v.id) > 0
        ORDER BY total_gastado DESC, total_compras DESC
        LIMIT 100
      `;
      
      try {
        const resultCorregida = await pool.query(queryCorregida);
        console.log(`   ✅ Consulta corregida exitosa: ${resultCorregida.rows.length} filas`);
        resultCorregida.rows.forEach((row, index) => {
          console.log(`   ${index + 1}. ${row.nombre}: ${row.puntos_fidelizacion} puntos → ${row.nivel_fidelidad}`);
        });
      } catch (error2) {
        console.log(`   ❌ Error en consulta corregida: ${error2.message}`);
      }
    }
    
    console.log('\n✅ Prueba de consulta completada');
    
  } catch (error) {
    console.error('❌ Error en prueba:', error);
  } finally {
    await pool.end();
  }
}

testSqlClientesFieles(); 