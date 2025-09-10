require('dotenv').config({ path: 'configuracion.env' });
const http = require('http');

async function testEndpointBeneficios() {
  try {
    console.log('🌐 Probando endpoint de beneficios...\n');
    
    // Simular una petición HTTP al endpoint
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/ventas/cliente/1/beneficios',
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        // Nota: En un entorno real necesitarías un token JWT válido
        'Authorization': 'Bearer test-token'
      }
    };
    
    const req = http.request(options, (res) => {
      console.log(`📡 Status: ${res.statusCode}`);
      console.log(`📡 Headers: ${JSON.stringify(res.headers)}`);
      
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
            console.log('\n✅ Endpoint funcionando correctamente');
            console.log(`👤 Cliente: ${response.data.cliente.nombre}`);
            console.log(`🎁 Beneficios disponibles: ${response.data.total_beneficios}`);
            
            if (response.data.beneficios_disponibles) {
              response.data.beneficios_disponibles.forEach((beneficio, index) => {
                console.log(`  ${index + 1}. ${beneficio.descripcion}`);
                console.log(`     Campaña: ${beneficio.campania_nombre}`);
                console.log(`     Mensaje: ${beneficio.mensaje}`);
              });
            }
          } else {
            console.log('\n❌ Error en la respuesta del endpoint');
          }
        } catch (e) {
          console.log('\n❌ Error parseando respuesta:', e);
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

testEndpointBeneficios(); 