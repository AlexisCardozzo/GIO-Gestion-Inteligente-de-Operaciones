const http = require('http');

// Función para probar la búsqueda
function testSearch(searchTerm) {
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: `/api/articulos?busqueda=${encodeURIComponent(searchTerm)}`,
    method: 'GET',
    headers: {
      'Content-Type': 'application/json'
    }
  };

  const req = http.request(options, (res) => {
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    res.on('end', () => {
      console.log(`\n=== Búsqueda: "${searchTerm}" ===`);
      console.log('Status:', res.statusCode);
      try {
        const response = JSON.parse(data);
        console.log('Productos encontrados:', response.data ? response.data.length : 0);
        if (response.data && response.data.length > 0) {
          response.data.forEach((producto, index) => {
            console.log(`${index + 1}. ${producto.nombre} (Código: ${producto.codigo}) - Stock: ${producto.stock_minimo}`);
          });
        } else {
          console.log('No se encontraron productos');
        }
      } catch (e) {
        console.log('Error parsing response:', e.message);
        console.log('Raw response:', data);
      }
    });
  });

  req.on('error', (e) => {
    console.error('Error:', e.message);
  });

  req.end();
}

// Probar diferentes términos de búsqueda
console.log('Probando búsqueda de productos...\n');

// Probar con diferentes términos
testSearch('test');
testSearch('123');
testSearch('producto');
testSearch('a'); 