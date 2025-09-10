require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testBeneficiosVenta() {
  try {
    console.log('🎁 Probando verificación de beneficios para venta...\n');
    
    // 1. Verificar clientes con beneficios
    console.log('👥 Clientes con beneficios disponibles:');
    const clientesResult = await pool.query(`
      SELECT DISTINCT 
        c.id,
        c.nombre,
        c.identificador,
        COUNT(fb.id) as total_beneficios
      FROM clientes c
      JOIN fidelizacion_clientes fcl ON c.id = fcl.cliente_id
      JOIN fidelizacion_campanias fc ON fcl.campania_id = fc.id
      JOIN fidelizacion_beneficios fb ON fc.id = fb.campania_id
      WHERE fc.activa = true 
      AND fc.fecha_inicio <= CURRENT_DATE 
      AND fc.fecha_fin >= CURRENT_DATE
      AND fcl.cumplio_requisitos = true
      GROUP BY c.id, c.nombre, c.identificador
      ORDER BY total_beneficios DESC
      LIMIT 3
    `);
    
    if (clientesResult.rows.length === 0) {
      console.log('  No hay clientes con beneficios disponibles');
      console.log('\n📋 Creando datos de prueba...');
      
      // Crear una campaña de prueba
      const campaniaQuery = `
        INSERT INTO fidelizacion_campanias (nombre, descripcion, fecha_inicio, fecha_fin, activa)
        VALUES ('Campaña de Prueba', 'Campaña para testing', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', true)
        RETURNING id
      `;
      const campaniaResult = await pool.query(campaniaQuery);
      const campaniaId = campaniaResult.rows[0].id;
      
      // Crear requisito
      await pool.query(`
        INSERT INTO fidelizacion_requisitos (campania_id, tipo, valor)
        VALUES ($1, 'compras', 1)
      `, [campaniaId]);
      
      // Crear beneficio
      await pool.query(`
        INSERT INTO fidelizacion_beneficios (campania_id, tipo, valor)
        VALUES ($1, 'descuento', 10)
      `, [campaniaId]);
      
      // Obtener primer cliente
      const clienteResult = await pool.query('SELECT id, nombre, identificador FROM clientes LIMIT 1');
      if (clienteResult.rows.length > 0) {
        const cliente = clienteResult.rows[0];
        
        // Marcar como que cumplió requisitos
        await pool.query(`
          INSERT INTO fidelizacion_clientes (cliente_id, campania_id, cumplio_requisitos, fecha_cumplimiento)
          VALUES ($1, $2, true, NOW())
          ON CONFLICT (cliente_id, campania_id) 
          DO UPDATE SET 
            cumplio_requisitos = true,
            fecha_cumplimiento = NOW()
        `, [cliente.id, campaniaId]);
        
        console.log(`✅ Datos de prueba creados para cliente: ${cliente.nombre}`);
        
        // Probar con este cliente
        await testClienteEspecifico(cliente.id);
      }
    } else {
      clientesResult.rows.forEach((cliente, index) => {
        console.log(`  ${index + 1}. ${cliente.nombre} (${cliente.identificador}) - ${cliente.total_beneficios} beneficios`);
      });
      
      // Probar con el primer cliente
      await testClienteEspecifico(clientesResult.rows[0].id);
    }
    
    console.log('\n✅ Prueba de beneficios completada');
    
  } catch (error) {
    console.error('❌ Error en prueba de beneficios:', error);
  } finally {
    await pool.end();
  }
}

async function testClienteEspecifico(clienteId) {
  console.log(`\n🎯 Probando cliente ID: ${clienteId}`);
  
  // Simular la consulta del endpoint
  const query = `
    SELECT 
      fb.id as beneficio_id,
      fb.tipo as beneficio_tipo,
      fb.valor as beneficio_valor,
      fc.id as campania_id,
      fc.nombre as campania_nombre,
      fc.fecha_inicio,
      fc.fecha_fin,
      fr.tipo as requisito_tipo,
      fr.valor as requisito_valor,
      fcl.cumplio_requisitos,
      fcl.fecha_cumplimiento,
      CASE 
        WHEN fcl.cumplio_requisitos = true AND fcl.fecha_cumplimiento IS NOT NULL THEN true
        ELSE false
      END as beneficio_disponible
    FROM fidelizacion_beneficios fb
    JOIN fidelizacion_campanias fc ON fb.campania_id = fc.id
    JOIN fidelizacion_requisitos fr ON fc.id = fr.campania_id
    LEFT JOIN fidelizacion_clientes fcl ON fc.id = fcl.campania_id AND fcl.cliente_id = $1
    WHERE fc.activa = true 
    AND fc.fecha_inicio <= CURRENT_DATE 
    AND fc.fecha_fin >= CURRENT_DATE
    AND fcl.cumplio_requisitos = true
    ORDER BY fc.fecha_fin ASC, fb.id ASC
  `;
  
  const result = await pool.query(query, [clienteId]);
  
  console.log(`📊 Beneficios encontrados: ${result.rows.length}`);
  
  result.rows.forEach((beneficio, index) => {
    console.log(`  ${index + 1}. ${beneficio.beneficio_tipo}: ${beneficio.beneficio_valor}${beneficio.beneficio_tipo === 'descuento' ? '%' : ''}`);
    console.log(`     Campaña: ${beneficio.campania_nombre}`);
    console.log(`     Requisito: ${beneficio.requisito_tipo} (${beneficio.requisito_valor})`);
    console.log(`     Válido hasta: ${beneficio.fecha_fin}`);
    console.log(`     Disponible: ${beneficio.beneficio_disponible ? 'Sí' : 'No'}`);
    console.log('');
  });
}

testBeneficiosVenta(); 