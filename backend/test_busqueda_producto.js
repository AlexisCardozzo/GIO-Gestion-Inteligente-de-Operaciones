const http = require('http');

const codigo = process.argv[2] || '14';
console.log('Buscando producto con código:', codigo);
const options = {
  hostname: 'localhost',
  port: 3000,
  path: `/api/articulos?busqueda=${encodeURIComponent(codigo)}`,
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
  },
};

const req = http.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    if (data) {
      console.log('Response:', data);
    } else {
      console.log('Respuesta vacía.');
    }
  });
});

req.on('error', (e) => {
  console.error('Error:', e);
});

req.end(); 