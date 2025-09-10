require('dotenv').config({ path: 'configuracion.env' });
const http = require('http');

async function testCorsHeaders() {
  try {
    console.log('🌐 Probando headers CORS y autenticación...\n');
    
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
            'Origin': 'http://localhost:8080',
            'Access-Control-Request-Method': 'GET',
            'Access-Control-Request-Headers': 'authorization,content-type',
            ...headers
          }
        };
        
        const req = http.request(options, (res) => {
          let data = '';
          res.on('data', (chunk) => {
            data += chunk;
          });
          
          res.on('end', () => {
            resolve({ 
              status: res.statusCode, 
              headers: res.headers,
              data: data 
            });
          });
        });
        
        req.on('error', (e) => {
          reject(e);
        });
        
        req.end();
      });
    }
    
    // 1. Probar OPTIONS request (CORS preflight)
    console.log('1️⃣ Probando OPTIONS request (CORS preflight)');
    try {
      const optionsResult = await makeRequest('/api/fidelizacion/clientes-fieles', 'OPTIONS');
      console.log(`   Status: ${optionsResult.status}`);
      console.log(`   CORS Headers:`);
      console.log(`   - Access-Control-Allow-Origin: ${optionsResult.headers['access-control-allow-origin']}`);
      console.log(`   - Access-Control-Allow-Methods: ${optionsResult.headers['access-control-allow-methods']}`);
      console.log(`   - Access-Control-Allow-Headers: ${optionsResult.headers['access-control-allow-headers']}`);
    } catch (error) {
      console.log(`   ❌ Error en OPTIONS: ${error.message}`);
    }
    
    // 2. Probar GET sin token
    console.log('\n2️⃣ Probando GET sin token');
    try {
      const noTokenResult = await makeRequest('/api/fidelizacion/clientes-fieles', 'GET');
      console.log(`   Status: ${noTokenResult.status}`);
      if (noTokenResult.status === 401) {
        console.log(`   ✅ Correcto: Requiere autenticación`);
      } else {
        console.log(`   ❌ Inesperado: ${noTokenResult.data}`);
      }
    } catch (error) {
      console.log(`   ❌ Error sin token: ${error.message}`);
    }
    
    // 3. Probar GET con token inválido
    console.log('\n3️⃣ Probando GET con token inválido');
    try {
      const invalidTokenResult = await makeRequest('/api/fidelizacion/clientes-fieles', 'GET', {
        'Authorization': 'Bearer invalid-token'
      });
      console.log(`   Status: ${invalidTokenResult.status}`);
      console.log(`   Response: ${invalidTokenResult.data}`);
    } catch (error) {
      console.log(`   ❌ Error con token inválido: ${error.message}`);
    }
    
    // 4. Verificar si el servidor está respondiendo
    console.log('\n4️⃣ Verificando si el servidor responde');
    try {
      const healthResult = await makeRequest('/', 'GET');
      console.log(`   Status: ${healthResult.status}`);
      console.log(`   Response: ${healthResult.data}`);
    } catch (error) {
      console.log(`   ❌ Servidor no responde: ${error.message}`);
    }
    
    console.log('\n✅ Prueba de CORS completada');
    
  } catch (error) {
    console.error('❌ Error en prueba:', error);
  }
}

testCorsHeaders(); 