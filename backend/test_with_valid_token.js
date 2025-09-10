require('dotenv').config({ path: 'configuracion.env' });
const http = require('http');
const jwt = require('jsonwebtoken');

async function testWithValidToken() {
  try {
    console.log('🔐 Probando endpoints con token válido...\n');
    
    // Crear un token válido para testing
    const testUser = {
      id: 1,
      email: 'test@test.com',
      rol: 'admin'
    };
    
    const token = jwt.sign(testUser, process.env.JWT_SECRET || 'tu_secreto_jwt', { expiresIn: '1h' });
    console.log(`Token generado: ${token.substring(0, 50)}...`);
    
    // Función para hacer petición HTTP
    function makeRequest(path, method = 'GET', headers = {}) {
      return new Promise((resolve, reject) => {
        const options = {
          hostname: '127.0.0.1',
          port: 3000,
          path: path,
          method: method,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
            ...headers
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
    console.log('1️⃣ Probando /api/fidelizacion/clientes-fieles con token válido');
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
    console.log('\n2️⃣ Probando /api/fidelizacion/estadisticas con token válido');
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
    
    console.log('\n✅ Prueba con token válido completada');
    
  } catch (error) {
    console.error('❌ Error en prueba:', error);
  }
}

testWithValidToken(); 