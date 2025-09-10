require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testCorregidoEstadisticas() {
  try {
    console.log('📊 Probando consulta corregida de estadísticas...\n');
    
    // Consulta corregida que suma puntos por cliente
    const nivelesQuery = `
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
    
    const result = await pool.query(nivelesQuery);
    
    console.log('📈 Distribución de niveles corregida:');
    result.rows.forEach((row) => {
      console.log(`  ${row.nivel_fidelidad}: ${row.cantidad_clientes} clientes`);
    });
    
    // Verificar clientes individuales
    console.log('\n👥 Verificando clientes individuales:');
    const clientesQuery = `
      SELECT 
        c.id,
        c.nombre,
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
      WHERE (c.activo = true OR c.activo IS NULL)
      GROUP BY c.id, c.nombre, fcl.puntos_acumulados
      HAVING COUNT(v.id) > 0
      ORDER BY fcl.puntos_acumulados DESC
    `;
    
    const clientesResult = await pool.query(clientesQuery);
    
    clientesResult.rows.forEach((cliente, index) => {
      console.log(`  ${index + 1}. ${cliente.nombre}: ${cliente.puntos_fidelizacion} puntos → ${cliente.nivel_fidelidad}`);
    });
    
    console.log('\n✅ Prueba de consulta corregida completada');
    
  } catch (error) {
    console.error('❌ Error en prueba:', error);
  } finally {
    await pool.end();
  }
}

testCorregidoEstadisticas(); 