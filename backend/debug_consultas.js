require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function debugConsultas() {
  try {
    console.log('🔍 Debuggeando consultas paso a paso...\n');
    
    // 1. Verificar datos básicos
    console.log('1️⃣ Verificando datos básicos:');
    const clientesQuery = 'SELECT COUNT(*) as total FROM clientes WHERE (activo = true OR activo IS NULL) AND usuario_id = [REPLACE_WITH_USER_ID]';
    // NOTE: Replace [REPLACE_WITH_USER_ID] with an actual user ID for debugging purposes.
    const clientesResult = await pool.query(clientesQuery);
    console.log(`   Total clientes: ${clientesResult.rows[0].total}`);
    
    const ventasQuery = 'SELECT COUNT(*) as total FROM ventas';
    const ventasResult = await pool.query(ventasQuery);
    console.log(`   Total ventas: ${ventasResult.rows[0].total}`);
    
    const fidelizacionQuery = 'SELECT COUNT(*) as total FROM fidelizacion_clientes';
    const fidelizacionResult = await pool.query(fidelizacionQuery);
    console.log(`   Total registros fidelización: ${fidelizacionResult.rows[0].total}`);
    
    // 2. Verificar datos de fidelización
    console.log('\n2️⃣ Verificando datos de fidelización:');
    const fidelizacionDetalleQuery = `
      SELECT 
        fcl.cliente_id,
        c.nombre,
        fcl.puntos_acumulados,
        fcl.campania_id
      FROM fidelizacion_clientes fcl
      JOIN clientes c ON fcl.cliente_id = c.id
      ORDER BY fcl.puntos_acumulados DESC
    `;
    const fidelizacionDetalleResult = await pool.query(fidelizacionDetalleQuery);
    console.log(`   Registros de fidelización: ${fidelizacionDetalleResult.rows.length}`);
    fidelizacionDetalleResult.rows.forEach((row, index) => {
      console.log(`   ${index + 1}. Cliente ${row.nombre} (ID: ${row.cliente_id}): ${row.puntos_acumulados} puntos en campaña ${row.campania_id}`);
    });
    
    // 3. Probar consulta de clientes fieles paso a paso
    console.log('\n3️⃣ Probando consulta de clientes fieles:');
    const clientesFielesQuery = `
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
      const clientesFielesResult = await pool.query(clientesFielesQuery);
      console.log(`   ✅ Clientes fieles obtenidos: ${clientesFielesResult.rows.length}`);
      clientesFielesResult.rows.forEach((cliente, index) => {
        console.log(`   ${index + 1}. ${cliente.nombre}: ${cliente.puntos_fidelizacion} puntos → ${cliente.nivel_fidelidad}`);
      });
    } catch (error) {
      console.log(`   ❌ Error en consulta de clientes fieles: ${error.message}`);
    }
    
    // 4. Probar consulta de estadísticas
    console.log('\n4️⃣ Probando consulta de estadísticas:');
    const estadisticasQuery = `
      SELECT 
        nivel_fidelidad,
        COUNT(*) as cantidad_clientes
      FROM (
        SELECT 
          c.id,
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
        WHERE (c.activo = true OR c.activo IS NULL)
        GROUP BY c.id, fcl.puntos_acumulados
        HAVING COUNT(v.id) > 0
      ) as clientes_con_nivel
      GROUP BY nivel_fidelidad
      ORDER BY 
        CASE nivel_fidelidad
          WHEN 'PLATINO' THEN 1
          WHEN 'ORO' THEN 2
          WHEN 'PLATA' THEN 3
          WHEN 'BRONCE' THEN 4
        END
    `;
    
    try {
      const estadisticasResult = await pool.query(estadisticasQuery);
      console.log(`   ✅ Estadísticas obtenidas: ${estadisticasResult.rows.length} filas`);
      estadisticasResult.rows.forEach((row) => {
        console.log(`   ${row.nivel_fidelidad}: ${row.cantidad_clientes} clientes`);
      });
    } catch (error) {
      console.log(`   ❌ Error en consulta de estadísticas: ${error.message}`);
    }
    
    console.log('\n✅ Debug completado');
    
  } catch (error) {
    console.error('❌ Error en debug:', error);
  } finally {
    await pool.end();
  }
}

debugConsultas();