require('dotenv').config({ path: 'configuracion.env' });
const http = require('http');

async function testEndpointsDirecto() {
  try {
    console.log('🌐 Probando endpoints directamente...\n');
    
    // Función para hacer petición HTTP
    function makeRequest(path, method = 'GET') {
      return new Promise((resolve, reject) => {
        const options = {
          hostname: 'localhost',
          port: 3000,
          path: path,
          method: method,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer test-token'
          }
        };
        
        const req = http.request(options, (res) => {
          let data = '';
          res.on('data', (chunk) => {
            data += chunk;
          });
          
          res.on('end', () => {
            try {
              const response = JSON.parse(data);
              resolve({ status: res.statusCode, data: response });
            } catch (e) {
              resolve({ status: res.statusCode, data: data });
            }
          });
        });
        
        req.on('error', (e) => {
          reject(e);
        });
        
        req.end();
      });
    }
    
    // 1. Probar endpoint de clientes fieles
    console.log('1️⃣ Probando /api/fidelizacion/clientes-fieles');
    try {
      const clientesResult = await makeRequest('/api/fidelizacion/clientes-fieles');
      console.log(`   Status: ${clientesResult.status}`);
      if (clientesResult.status === 200 && clientesResult.data.success) {
        console.log(`   ✅ Clientes fieles: ${clientesResult.data.data.length} clientes`);
        clientesResult.data.data.forEach((cliente, index) => {
          console.log(`   ${index + 1}. ${cliente.nombre}: ${cliente.puntos_fidelizacion} puntos → ${cliente.nivel_fidelidad}`);
        });
      } else {
        console.log(`   ❌ Error: ${JSON.stringify(clientesResult.data)}`);
      }
    } catch (error) {
      console.log(`   ❌ Error de conexión: ${error.message}`);
    }
    
    // 2. Probar endpoint de estadísticas
    console.log('\n2️⃣ Probando /api/fidelizacion/estadisticas');
    try {
      const estadisticasResult = await makeRequest('/api/fidelizacion/estadisticas');
      console.log(`   Status: ${estadisticasResult.status}`);
      if (estadisticasResult.status === 200 && estadisticasResult.data.success) {
        console.log(`   ✅ Estadísticas obtenidas`);
        if (estadisticasResult.data.data.niveles_fidelidad) {
          Object.entries(estadisticasResult.data.data.niveles_fidelidad).forEach(([nivel, cantidad]) => {
            console.log(`   ${nivel}: ${cantidad} clientes`);
          });
        } else {
          console.log(`   ❌ No se encontraron niveles de fidelidad`);
        }
      } else {
        console.log(`   ❌ Error: ${JSON.stringify(estadisticasResult.data)}`);
      }
    } catch (error) {
      console.log(`   ❌ Error de conexión: ${error.message}`);
    }
    
    console.log('\n✅ Prueba de endpoints completada');
    
  } catch (error) {
    console.error('❌ Error en prueba:', error);
  }
}

testEndpointsDirecto(); 