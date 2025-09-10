require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testSimpleBeneficios() {
  try {
    console.log('🎁 Probando consulta simple de beneficios...\n');
    
    // Consulta directa
    const query = `
      SELECT 
        fb.id as beneficio_id,
        fb.tipo as beneficio_tipo,
        fb.valor as beneficio_valor,
        fc.nombre as campania_nombre,
        fr.tipo as requisito_tipo,
        fr.valor as requisito_valor,
        CASE 
          WHEN fr.tipo = 'compras' THEN 11 >= fr.valor
          WHEN fr.tipo = 'monto' THEN 45500 >= fr.valor
          ELSE false
        END as cumple_requisitos
      FROM fidelizacion_beneficios fb
      JOIN fidelizacion_campanias fc ON fb.campania_id = fc.id
      JOIN fidelizacion_requisitos fr ON fc.id = fr.campania_id
      WHERE fc.activa = true
    `;
    
    const result = await pool.query(query);
    
    console.log(`📋 Beneficios encontrados: ${result.rows.length}`);
    
    result.rows.forEach((row, index) => {
      console.log(`\n${index + 1}. Beneficio ID: ${row.beneficio_id}`);
      console.log(`   Campaña: ${row.campania_nombre}`);
      console.log(`   Tipo: ${row.beneficio_tipo}`);
      console.log(`   Valor: ${row.beneficio_valor}`);
      console.log(`   Requisito: ${row.requisito_tipo} - ${row.requisito_valor}`);
      console.log(`   Cumple requisitos: ${row.cumple_requisitos ? '✅ SÍ' : '❌ NO'}`);
    });
    
    console.log('\n✅ Prueba completada');
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await pool.end();
  }
}

testSimpleBeneficios(); 