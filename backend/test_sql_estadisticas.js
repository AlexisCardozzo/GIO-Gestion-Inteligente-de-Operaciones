require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testSQLEstadisticas() {
  try {
    console.log('📊 Probando consulta SQL de estadísticas...\n');
    
    // Probar la consulta de niveles paso a paso
    console.log('1️⃣ Probando consulta interna de clientes con nivel:');
    const clientesConNivelQuery = `
      SELECT 
        c.id,
        c.nombre,
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
      WHERE (c.activo = true OR c.activo IS NULL)
      GROUP BY c.id, c.nombre
      HAVING COUNT(v.id) > 0
    `;
    
    const clientesResult = await pool.query(clientesConNivelQuery);
    console.log(`✅ Clientes con nivel calculado: ${clientesResult.rows.length}`);
    
    clientesResult.rows.forEach((cliente, index) => {
      console.log(`  ${index + 1}. ${cliente.nombre}: ${cliente.puntos_fidelizacion} puntos → ${cliente.nivel_fidelidad}`);
    });
    
    console.log('\n2️⃣ Probando consulta completa de estadísticas:');
    const nivelesQuery = `
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
        LEFT JOIN fidelizacion_clientes fcl ON c.id = fcl.cliente_id
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
    
    const nivelesResult = await pool.query(nivelesQuery);
    console.log(`✅ Resultados de niveles: ${nivelesResult.rows.length} filas`);
    
    nivelesResult.rows.forEach((row) => {
      console.log(`  ${row.nivel_fidelidad}: ${row.cantidad_clientes} clientes`);
    });
    
    // Verificar si hay algún problema con los datos
    console.log('\n3️⃣ Verificando datos de fidelización:');
    const fidelizacionQuery = `
      SELECT 
        fcl.cliente_id,
        c.nombre,
        fcl.puntos_acumulados,
        fcl.campania_id
      FROM fidelizacion_clientes fcl
      JOIN clientes c ON fcl.cliente_id = c.id
      WHERE fcl.puntos_acumulados > 0
      ORDER BY fcl.puntos_acumulados DESC
    `;
    
    const fidelizacionResult = await pool.query(fidelizacionQuery);
    console.log(`✅ Registros de fidelización: ${fidelizacionResult.rows.length}`);
    
    fidelizacionResult.rows.forEach((row) => {
      console.log(`  Cliente ${row.nombre} (ID: ${row.cliente_id}): ${row.puntos_acumulados} puntos en campaña ${row.campania_id}`);
    });
    
    console.log('\n✅ Prueba de SQL completada');
    
  } catch (error) {
    console.error('❌ Error en prueba:', error);
  } finally {
    await pool.end();
  }
}

testSQLEstadisticas(); 