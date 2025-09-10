const axios = require('axios');

// Configuración
const BASE_URL = 'http://127.0.0.1:3000/api';
const TEST_TOKEN = 'test_token'; // Reemplazar con un token válido

async function testClientesRiesgo() {
  console.log('🧪 Iniciando pruebas de clientes en riesgo...\n');

  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${TEST_TOKEN}`
  };

  try {
    // 1. Probar análisis de clientes en riesgo
    console.log('1️⃣ Probando análisis de clientes en riesgo...');
    try {
      const response = await axios.get(`${BASE_URL}/fidelizacion/clientes-riesgo/analizar`, { headers });
      console.log('✅ Análisis completado:', response.data);
    } catch (error) {
      console.log('❌ Error en análisis:', error.response?.data || error.message);
    }

    // 2. Probar listar clientes en riesgo
    console.log('\n2️⃣ Probando listar clientes en riesgo...');
    try {
      const response = await axios.get(`${BASE_URL}/fidelizacion/clientes-riesgo`, { headers });
      console.log('✅ Clientes en riesgo encontrados:', response.data.data?.length || 0);
      if (response.data.data && response.data.data.length > 0) {
        console.log('📋 Primer cliente:', {
          nombre: response.data.data[0].cliente_nombre,
          nivel_riesgo: response.data.data[0].nivel_riesgo,
          dias_sin_comprar: response.data.data[0].dias_sin_comprar,
          producto_favorito: response.data.data[0].producto_favorito
        });
      }
    } catch (error) {
      console.log('❌ Error listando clientes:', error.response?.data || error.message);
    }

    // 3. Probar estadísticas de retención
    console.log('\n3️⃣ Probando estadísticas de retención...');
    try {
      const response = await axios.get(`${BASE_URL}/fidelizacion/clientes-riesgo/estadisticas`, { headers });
      console.log('✅ Estadísticas obtenidas:', response.data.data);
    } catch (error) {
      console.log('❌ Error obteniendo estadísticas:', error.response?.data || error.message);
    }

    // 4. Probar envío de mensaje (si hay clientes)
    console.log('\n4️⃣ Probando envío de mensaje...');
    try {
      const clientesResponse = await axios.get(`${BASE_URL}/fidelizacion/clientes-riesgo`, { headers });
      if (clientesResponse.data.data && clientesResponse.data.data.length > 0) {
        const primerCliente = clientesResponse.data.data[0];
        const mensajeData = {
          mensaje: 'Hola! Te hemos extrañado mucho. Tenemos un descuento especial para ti.',
          nivel_riesgo: primerCliente.nivel_riesgo
        };
        
        const response = await axios.post(
          `${BASE_URL}/fidelizacion/clientes-riesgo/${primerCliente.cliente_id}/mensaje`,
          mensajeData,
          { headers }
        );
        console.log('✅ Mensaje enviado:', response.data);
      } else {
        console.log('ℹ️ No hay clientes en riesgo para probar envío de mensaje');
      }
    } catch (error) {
      console.log('❌ Error enviando mensaje:', error.response?.data || error.message);
    }

    console.log('\n🎉 Pruebas completadas!');

  } catch (error) {
    console.error('❌ Error general en las pruebas:', error.message);
  }
}

// Ejecutar pruebas
testClientesRiesgo(); 