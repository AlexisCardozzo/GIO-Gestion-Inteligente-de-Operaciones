require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testCanjeBeneficio() {
  try {
    console.log('🎁 Probando canje de beneficio...\n');
    
    // 1. Verificar estado actual
    console.log('📊 Estado actual:');
    const estadoActual = await pool.query(`
      SELECT 
        c.nombre as cliente,
        fc.nombre as campania,
        fcl.cumplio_requisitos,
        fcl.fecha_cumplimiento,
        fb.tipo as beneficio_tipo,
        fb.valor as beneficio_valor
      FROM fidelizacion_clientes fcl
      JOIN clientes c ON fcl.cliente_id = c.id
      JOIN fidelizacion_campanias fc ON fcl.campania_id = fc.id
      JOIN fidelizacion_beneficios fb ON fc.id = fb.campania_id
      WHERE fcl.cliente_id = 1 AND fcl.campania_id = 1
    `);
    
    if (estadoActual.rows.length > 0) {
      const estado = estadoActual.rows[0];
      console.log(`  Cliente: ${estado.cliente}`);
      console.log(`  Campaña: ${estado.campania}`);
      console.log(`  Cumplió requisitos: ${estado.cumplio_requisitos ? 'SÍ' : 'NO'}`);
      console.log(`  Fecha cumplimiento: ${estado.fecha_cumplimiento || 'No registrada'}`);
      console.log(`  Beneficio: ${estado.beneficio_tipo} - ${estado.beneficio_valor}`);
    } else {
      console.log('  No hay registro de participación');
    }
    
    // 2. Simular canje de beneficio
    console.log('\n🔄 Simulando canje...');
    const canjeQuery = `
      INSERT INTO fidelizacion_clientes (cliente_id, campania_id, cumplio_requisitos, fecha_cumplimiento)
      VALUES ($1, $2, true, NOW())
      ON CONFLICT (cliente_id, campania_id) 
      DO UPDATE SET 
        cumplio_requisitos = true,
        fecha_cumplimiento = NOW()
    `;
    
    await pool.query(canjeQuery, [1, 1]);
    console.log('✅ Canje registrado exitosamente');
    
    // 3. Verificar estado después del canje
    console.log('\n📊 Estado después del canje:');
    const estadoDespues = await pool.query(`
      SELECT 
        c.nombre as cliente,
        fc.nombre as campania,
        fcl.cumplio_requisitos,
        fcl.fecha_cumplimiento,
        fb.tipo as beneficio_tipo,
        fb.valor as beneficio_valor
      FROM fidelizacion_clientes fcl
      JOIN clientes c ON fcl.cliente_id = c.id
      JOIN fidelizacion_campanias fc ON fcl.campania_id = fc.id
      JOIN fidelizacion_beneficios fb ON fc.id = fb.campania_id
      WHERE fcl.cliente_id = 1 AND fcl.campania_id = 1
    `);
    
    if (estadoDespues.rows.length > 0) {
      const estado = estadoDespues.rows[0];
      console.log(`  Cliente: ${estado.cliente}`);
      console.log(`  Campaña: ${estado.campania}`);
      console.log(`  Cumplió requisitos: ${estado.cumplio_requisitos ? 'SÍ' : 'NO'}`);
      console.log(`  Fecha cumplimiento: ${estado.fecha_cumplimiento || 'No registrada'}`);
      console.log(`  Beneficio: ${estado.beneficio_tipo} - ${estado.beneficio_valor}`);
    }
    
    console.log('\n✅ Prueba de canje completada');
    
  } catch (error) {
    console.error('❌ Error en prueba de canje:', error);
  } finally {
    await pool.end();
  }
}

testCanjeBeneficio(); 