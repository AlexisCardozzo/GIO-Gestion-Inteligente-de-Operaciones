require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function recalcularPuntosVentas() {
  try {
    console.log('🔄 Recalculando puntos de fidelización para todas las ventas...\n');
    
    // 1. Obtener todas las ventas
    const ventasQuery = `
      SELECT 
        v.id,
        v.cliente_id,
        v.total,
        v.fecha
      FROM ventas v
      ORDER BY v.fecha ASC
    `;
    
    const ventasResult = await pool.query(ventasQuery);
    const ventas = ventasResult.rows;
    
    console.log(`📊 Encontradas ${ventas.length} ventas para procesar`);
    
    // 2. Obtener campañas activas
    const campaniasQuery = `
      SELECT id, nombre, activa
      FROM fidelizacion_campanias
      WHERE activa = true
    `;
    
    const campaniasResult = await pool.query(campaniasQuery);
    const campaniasActivas = campaniasResult.rows;
    
    console.log(`🏆 Encontradas ${campaniasActivas.length} campañas activas`);
    
    if (campaniasActivas.length === 0) {
      console.log('⚠️ No hay campañas activas. Los puntos se calcularán cuando se creen campañas.');
      return;
    }
    
    let totalPuntosCalculados = 0;
    let ventasProcesadas = 0;
    
    // 3. Procesar cada venta
    for (const venta of ventas) {
      const montoVenta = parseFloat(venta.total) || 0;
      const puntosGanados = Math.floor(montoVenta / 1000);
      
      if (puntosGanados > 0) {
        console.log(`💰 Venta ${venta.id}: Cliente ${venta.cliente_id}, Monto: ${montoVenta}, Puntos: +${puntosGanados}`);
        
        // 4. Actualizar puntos en cada campaña activa
        for (const campania of campaniasActivas) {
          // Verificar si el cliente ya tiene puntos en esta campaña
          const puntosActualesQuery = `
            SELECT puntos_acumulados
            FROM fidelizacion_clientes
            WHERE cliente_id = $1 AND campania_id = $2
          `;
          
          const puntosActualesResult = await pool.query(puntosActualesQuery, [venta.cliente_id, campania.id]);
          const puntosActuales = puntosActualesResult.rows.length > 0 ? (puntosActualesResult.rows[0].puntos_acumulados || 0) : 0;
          const nuevosPuntos = puntosActuales + puntosGanados;
          
          // Insertar o actualizar puntos
          const upsertQuery = `
            INSERT INTO fidelizacion_clientes (cliente_id, campania_id, puntos_acumulados, ultima_actualizacion)
            VALUES ($1, $2, $3, NOW())
            ON CONFLICT (cliente_id, campania_id) 
            DO UPDATE SET 
              puntos_acumulados = $3,
              ultima_actualizacion = NOW()
          `;
          
          await pool.query(upsertQuery, [venta.cliente_id, campania.id, nuevosPuntos]);
          totalPuntosCalculados += puntosGanados;
        }
        
        ventasProcesadas++;
      }
    }
    
    console.log(`\n✅ Proceso completado:`);
    console.log(`  - Ventas procesadas: ${ventasProcesadas}`);
    console.log(`  - Puntos totales calculados: ${totalPuntosCalculados}`);
    console.log(`  - Campañas activas: ${campaniasActivas.length}`);
    
    // 5. Verificar resultado final
    const puntosFinalesQuery = `
      SELECT 
        COALESCE(SUM(fcl.puntos_acumulados), 0) as total_puntos_fidelizacion,
        COUNT(fcl.id) as registros_fidelizacion
      FROM fidelizacion_clientes fcl
      WHERE fcl.puntos_acumulados > 0
    `;
    
    const puntosFinalesResult = await pool.query(puntosFinalesQuery);
    const puntosFinales = puntosFinalesResult.rows[0];
    
    console.log(`\n🎯 Puntos finales en el sistema:`);
    console.log(`  - Total puntos: ${puntosFinales.total_puntos_fidelizacion}`);
    console.log(`  - Registros con puntos: ${puntosFinales.registros_fidelizacion}`);
    
  } catch (error) {
    console.error('❌ Error recalculando puntos:', error);
  } finally {
    await pool.end();
  }
}

recalcularPuntosVentas(); 