require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testProgresoBuho() {
  try {
    console.log('🦉 Probando progreso del búho...\n');
    
    // 1. Verificar ventas totales
    const ventasQuery = `
      SELECT 
        COUNT(v.id) as total_ventas,
        COALESCE(SUM(v.total), 0) as total_ventas_monto,
        COUNT(DISTINCT v.cliente_id) as clientes_unicos
      FROM ventas v
    `;
    
    const ventasResult = await pool.query(ventasQuery);
    const ventasData = ventasResult.rows[0];
    
    console.log('📊 Ventas totales:', {
      total_ventas: ventasData.total_ventas,
      total_monto: ventasData.total_ventas_monto,
      clientes_unicos: ventasData.clientes_unicos
    });
    
    // 2. Verificar puntos de fidelización
    const puntosQuery = `
      SELECT 
        COALESCE(SUM(fcl.puntos_acumulados), 0) as total_puntos_fidelizacion,
        COUNT(fcl.id) as registros_fidelizacion
      FROM fidelizacion_clientes fcl
      WHERE fcl.puntos_acumulados > 0
    `;
    
    const puntosResult = await pool.query(puntosQuery);
    const puntosData = puntosResult.rows[0];
    
    console.log('🎯 Puntos de fidelización:', {
      total_puntos: puntosData.total_puntos_fidelizacion,
      registros_con_puntos: puntosData.registros_fidelizacion
    });
    
    // 3. Verificar campañas activas
    const campaniasQuery = `
      SELECT 
        COUNT(*) as total_campanias,
        COUNT(CASE WHEN activa = true THEN 1 END) as campanias_activas
      FROM fidelizacion_campanias
    `;
    
    const campaniasResult = await pool.query(campaniasQuery);
    const campaniasData = campaniasResult.rows[0];
    
    console.log('🏆 Campañas:', {
      total_campanias: campaniasData.total_campanias,
      campanias_activas: campaniasData.campanias_activas
    });
    
    // 4. Verificar clientes con puntos por campaña
    const clientesPuntosQuery = `
      SELECT 
        fc.nombre as campania,
        fc.activa,
        COUNT(fcl.cliente_id) as clientes_participando,
        COALESCE(SUM(fcl.puntos_acumulados), 0) as puntos_campania
      FROM fidelizacion_campanias fc
      LEFT JOIN fidelizacion_clientes fcl ON fc.id = fcl.campania_id
      GROUP BY fc.id, fc.nombre, fc.activa
      ORDER BY fc.creada_en DESC
    `;
    
    const clientesPuntosResult = await pool.query(clientesPuntosQuery);
    
    console.log('👥 Clientes por campaña:');
    clientesPuntosResult.rows.forEach(row => {
      console.log(`  - ${row.campania} (${row.activa ? 'Activa' : 'Inactiva'}): ${row.clientes_participando} clientes, ${row.puntos_campania} puntos`);
    });
    
    // 5. Calcular nivel del búho
    const totalVentas = parseInt(ventasData.total_ventas) || 0;
    const totalPuntos = parseInt(puntosData.total_puntos_fidelizacion) || 0;
    
    let nivelBuho = 1;
    let nombreNivel = 'Huevo';
    let progreso = 0;
    
    if (totalVentas >= 50 && totalPuntos >= 100) {
      nivelBuho = 5;
      nombreNivel = 'Búho Legendario';
      progreso = 1.0;
    } else if (totalVentas >= 30 && totalPuntos >= 60) {
      nivelBuho = 4;
      nombreNivel = 'Búho Sabio';
      progreso = Math.min((totalVentas - 30) / 20 + (totalPuntos - 60) / 40, 1.0);
    } else if (totalVentas >= 15 && totalPuntos >= 30) {
      nivelBuho = 3;
      nombreNivel = 'Búho Adulto';
      progreso = Math.min((totalVentas - 15) / 15 + (totalPuntos - 30) / 30, 1.0);
    } else if (totalVentas >= 5 && totalPuntos >= 10) {
      nivelBuho = 2;
      nombreNivel = 'Polluelo';
      progreso = Math.min((totalVentas - 5) / 10 + (totalPuntos - 10) / 20, 1.0);
    } else {
      nivelBuho = 1;
      nombreNivel = 'Huevo';
      progreso = Math.min(totalVentas / 5 + totalPuntos / 10, 1.0);
    }
    
    console.log('\n🦉 Resultado del búho:');
    console.log(`  Nivel: ${nivelBuho} - ${nombreNivel}`);
    console.log(`  Progreso: ${Math.round(progreso * 100)}%`);
    console.log(`  Ventas: ${totalVentas}`);
    console.log(`  Puntos: ${totalPuntos}`);
    
  } catch (error) {
    console.error('❌ Error en prueba:', error);
  } finally {
    await pool.end();
  }
}

testProgresoBuho(); 