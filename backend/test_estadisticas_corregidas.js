require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testEstadisticasCorregidas() {
  try {
    console.log('📊 Probando estadísticas corregidas...\n');
    
    // Usar la misma consulta que el endpoint de estadísticas
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
    
    const result = await pool.query(nivelesQuery);
    
    console.log('📈 Distribución de niveles en estadísticas:');
    result.rows.forEach((row) => {
      console.log(`  ${row.nivel_fidelidad}: ${row.cantidad_clientes} clientes`);
    });
    
    // Comparar con la lista de clientes fieles
    console.log('\n🔍 Comparando con lista de clientes fieles:');
    const clientesQuery = `
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
      WHERE c.activo = true OR c.activo IS NULL
      GROUP BY c.id, c.nombre
      HAVING COUNT(v.id) > 0
      ORDER BY puntos_fidelizacion DESC
    `;
    
    const clientesResult = await pool.query(clientesQuery);
    
    console.log('👥 Clientes individuales:');
    clientesResult.rows.forEach((cliente, index) => {
      console.log(`  ${index + 1}. ${cliente.nombre}: ${cliente.puntos_fidelizacion} puntos → ${cliente.nivel_fidelidad}`);
    });
    
    // Verificar consistencia
    const nivelesEnClientes = clientesResult.rows.reduce((acc, cliente) => {
      acc[cliente.nivel_fidelidad] = (acc[cliente.nivel_fidelidad] || 0) + 1;
      return acc;
    }, {});
    
    console.log('\n✅ Verificación de consistencia:');
    console.log('Estadísticas vs Lista de clientes:');
    result.rows.forEach((row) => {
      const enClientes = nivelesEnClientes[row.nivel_fidelidad] || 0;
      const coincide = row.cantidad_clientes == enClientes;
      console.log(`  ${row.nivel_fidelidad}: ${row.cantidad_clientes} vs ${enClientes} ${coincide ? '✅' : '❌'}`);
    });
    
    console.log('\n✅ Prueba de estadísticas completada');
    
  } catch (error) {
    console.error('❌ Error en prueba:', error);
  } finally {
    await pool.end();
  }
}

testEstadisticasCorregidas(); 