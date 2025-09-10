require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function debugEstadisticas() {
  try {
    console.log('🔍 Debuggeando estadísticas...\n');
    
    // 1. Verificar datos de fidelización
    console.log('1️⃣ Verificando datos de fidelización:');
    const fidelizacionQuery = `
      SELECT 
        fcl.cliente_id,
        c.nombre,
        fcl.puntos_acumulados,
        fcl.campania_id
      FROM fidelizacion_clientes fcl
      JOIN clientes c ON fcl.cliente_id = c.id
      ORDER BY fcl.puntos_acumulados DESC
    `;
    const fidelizacionResult = await pool.query(fidelizacionQuery);
    console.log(`   Registros de fidelización: ${fidelizacionResult.rows.length}`);
    fidelizacionResult.rows.forEach((row, index) => {
      console.log(`   ${index + 1}. Cliente ${row.nombre} (ID: ${row.cliente_id}): ${row.puntos_acumulados} puntos en campaña ${row.campania_id}`);
    });
    
    // 2. Verificar suma de puntos por cliente
    console.log('\n2️⃣ Verificando suma de puntos por cliente:');
    const sumaPuntosQuery = `
      SELECT 
        cliente_id,
        SUM(puntos_acumulados) as total_puntos
      FROM fidelizacion_clientes
      GROUP BY cliente_id
      ORDER BY total_puntos DESC
    `;
    const sumaPuntosResult = await pool.query(sumaPuntosQuery);
    console.log(`   Suma de puntos por cliente: ${sumaPuntosResult.rows.length} clientes`);
    sumaPuntosResult.rows.forEach((row, index) => {
      console.log(`   ${index + 1}. Cliente ID ${row.cliente_id}: ${row.total_puntos} puntos totales`);
    });
    
    // 3. Probar la consulta de niveles paso a paso
    console.log('\n3️⃣ Probando consulta de niveles paso a paso:');
    const nivelesQuery = `
      SELECT 
        c.id,
        c.nombre,
        COALESCE(SUM(fcl.puntos_acumulados), 0) as puntos_totales,
        CASE 
          WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 100 THEN 'PLATINO'
          WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 50 THEN 'ORO'
          WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 20 THEN 'PLATA'
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
      GROUP BY c.id, c.nombre
      HAVING COUNT(v.id) > 0
      ORDER BY puntos_totales DESC
    `;
    
    const nivelesResult = await pool.query(nivelesQuery);
    console.log(`   Clientes con niveles: ${nivelesResult.rows.length}`);
    nivelesResult.rows.forEach((row, index) => {
      console.log(`   ${index + 1}. ${row.nombre}: ${row.puntos_totales} puntos → ${row.nivel_fidelidad}`);
    });
    
    // 4. Probar la consulta final de estadísticas
    console.log('\n4️⃣ Probando consulta final de estadísticas:');
    const estadisticasQuery = `
      SELECT 
        nivel_fidelidad,
        COUNT(*) as cantidad_clientes
      FROM (
        SELECT 
          c.id,
          CASE 
            WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 100 THEN 'PLATINO'
            WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 50 THEN 'ORO'
            WHEN COALESCE(SUM(fcl.puntos_acumulados), 0) >= 20 THEN 'PLATA'
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
        GROUP BY c.id
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
    
    const estadisticasResult = await pool.query(estadisticasQuery);
    console.log(`   Estadísticas finales: ${estadisticasResult.rows.length} niveles`);
    estadisticasResult.rows.forEach((row) => {
      console.log(`   ${row.nivel_fidelidad}: ${row.cantidad_clientes} clientes`);
    });
    
    console.log('\n✅ Debug completado');
    
  } catch (error) {
    console.error('❌ Error en debug:', error);
  } finally {
    await pool.end();
  }
}

debugEstadisticas(); 