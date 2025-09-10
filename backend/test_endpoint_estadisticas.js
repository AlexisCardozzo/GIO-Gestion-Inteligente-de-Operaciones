require('dotenv').config({ path: 'configuracion.env' });
const http = require('http');

async function testEndpointEstadisticas() {
  try {
    console.log('📊 Probando endpoint de estadísticas...\n');
    
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/fidelizacion/estadisticas',
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
          console.log(JSON.stringify(response, null, 2));
          
          if (response.success && response.data) {
            console.log('\n✅ Estadísticas obtenidas correctamente');
            console.log('Niveles de fidelidad:');
            if (response.data.niveles_fidelidad) {
              Object.entries(response.data.niveles_fidelidad).forEach(([nivel, cantidad]) => {
                console.log(`  ${nivel}: ${cantidad} clientes`);
              });
            } else {
              console.log('  ❌ No se encontraron niveles de fidelidad');
            }
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

testEndpointEstadisticas(); 