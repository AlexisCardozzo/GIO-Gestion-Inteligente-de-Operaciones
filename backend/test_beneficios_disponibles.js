require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testBeneficiosDisponibles() {
  try {
    console.log('🎁 Probando endpoint de beneficios disponibles...\n');
    
    // 1. Obtener un cliente con puntos
    const clienteResult = await pool.query(`
      SELECT 
        c.id,
        c.nombre,
        COUNT(v.id) as total_compras,
        COALESCE(SUM(v.total), 0) as total_gastado
      FROM clientes c
      LEFT JOIN ventas v ON c.id = v.cliente_id
      WHERE c.id IN (
        SELECT DISTINCT cliente_id 
        FROM fidelizacion_clientes 
        WHERE puntos_acumulados > 0
      )
      GROUP BY c.id, c.nombre
      LIMIT 1
    `);
    
    if (clienteResult.rows.length === 0) {
      console.log('❌ No hay clientes con puntos para probar');
      return;
    }
    
    const cliente = clienteResult.rows[0];
    console.log(`👤 Probando con cliente: ${cliente.nombre} (ID: ${cliente.id})`);
    console.log(`   Compras: ${cliente.total_compras}`);
    console.log(`   Total gastado: Gs ${cliente.total_gastado}\n`);
    
        // 2. Simular la consulta del endpoint
    const beneficiosQuery = `
      SELECT 
        fb.id as beneficio_id,
        fb.tipo as beneficio_tipo,
        fb.valor as beneficio_valor,
        fc.id as campania_id,
        fc.nombre as campania_nombre,
        fc.activa as campania_activa,
        fr.tipo as requisito_tipo,
        fr.valor as requisito_valor,
        'Requisito de ' || fr.tipo as requisito_descripcion,
        CASE 
          WHEN fr.tipo = 'compras' THEN ${cliente.total_compras} >= fr.valor
          WHEN fr.tipo = 'monto' THEN ${cliente.total_gastado} >= fr.valor
          ELSE false
        END as cumple_requisitos
      FROM fidelizacion_beneficios fb
      JOIN fidelizacion_campanias fc ON fb.campania_id = fc.id
      JOIN fidelizacion_requisitos fr ON fc.id = fr.campania_id
      WHERE fc.activa = true
      ORDER BY fc.nombre, fb.id
    `;
    
    const beneficiosResult = await pool.query(beneficiosQuery);
    
    console.log(`📋 Beneficios encontrados: ${beneficiosResult.rows.length}`);
    
    if (beneficiosResult.rows.length > 0) {
      console.log('\n🎁 Detalle de beneficios:');
      
      // Agrupar por campaña
      const beneficiosPorCampania = {};
      beneficiosResult.rows.forEach(row => {
        if (!beneficiosPorCampania[row.campania_id]) {
          beneficiosPorCampania[row.campania_id] = {
            campania_nombre: row.campania_nombre,
            beneficios: []
          };
        }
        
        beneficiosPorCampania[row.campania_id].beneficios.push({
          beneficio_id: row.beneficio_id,
          beneficio_tipo: row.beneficio_tipo,
          beneficio_valor: row.beneficio_valor,
          requisito_tipo: row.requisito_tipo,
          requisito_valor: row.requisito_valor,
          requisito_descripcion: row.requisito_descripcion,
          cumple_requisitos: row.cumple_requisitos
        });
      });
      
      Object.values(beneficiosPorCampania).forEach(campania => {
        console.log(`\n📢 Campaña: ${campania.campania_nombre}`);
        campania.beneficios.forEach(beneficio => {
          const status = beneficio.cumple_requisitos ? '✅ DISPONIBLE' : '❌ NO DISPONIBLE';
          console.log(`  ${status} - ${beneficio.beneficio_tipo} - ${beneficio.beneficio_valor}`);
          console.log(`    Tipo: ${beneficio.beneficio_tipo}`);
          console.log(`    Valor: ${beneficio.beneficio_valor}`);
          console.log(`    Requisito: ${beneficio.requisito_tipo} - ${beneficio.requisito_valor}`);
          console.log(`    Descripción requisito: ${beneficio.requisito_descripcion || 'Sin descripción'}`);
        });
      });
    } else {
      console.log('❌ No hay beneficios configurados');
    }
    
    console.log('\n✅ Prueba del endpoint completada');
    
  } catch (error) {
    console.error('❌ Error probando endpoint:', error);
  } finally {
    await pool.end();
  }
}

testBeneficiosDisponibles(); 