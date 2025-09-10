require('dotenv').config({ path: 'configuracion.env' });
const http = require('http');

async function testClientesFielesEndpoint() {
  try {
    console.log('👥 Probando endpoint de clientes fieles...\n');
    
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/fidelizacion/clientes-fieles',
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer test-token'
      }
    };
    
    const req = http.request(options, (res) => {
      console.log(`📡 Status: ${res.statusCode}`);
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          console.log('\n📋 Respuesta del endpoint:');
          
          if (response.success && response.data) {
            console.log(`✅ Clientes fieles obtenidos: ${response.data.length}`);
            
            response.data.forEach((cliente, index) => {
              console.log(`\n  ${index + 1}. ${cliente.nombre} (${cliente.ci_ruc})`);
              console.log(`     Compras: ${cliente.total_compras}`);
              console.log(`     Total gastado: Gs ${cliente.total_gastado}`);
              console.log(`     Puntos: ${cliente.puntos_fidelizacion}`);
              console.log(`     Nivel: ${cliente.nivel_fidelidad}`);
            });
            
            // Verificar distribución de niveles
            const niveles = response.data.reduce((acc, cliente) => {
              acc[cliente.nivel_fidelidad] = (acc[cliente.nivel_fidelidad] || 0) + 1;
              return acc;
            }, {});
            
            console.log('\n📊 Distribución de niveles:');
            Object.entries(niveles).forEach(([nivel, cantidad]) => {
              console.log(`  ${nivel}: ${cantidad} clientes`);
            });
            
          } else {
            console.log('❌ Error en la respuesta:', response);
          }
        } catch (e) {
          console.log('❌ Error parseando respuesta:', e);
          console.log('Respuesta cruda:', data);
        }
      });
    });
    
    req.on('error', (e) => {
      console.error('❌ Error en la petición:', e);
    });
    
    req.end();
    
  } catch (error) {
    console.error('❌ Error en prueba:', error);
  }
}

testClientesFielesEndpoint(); 