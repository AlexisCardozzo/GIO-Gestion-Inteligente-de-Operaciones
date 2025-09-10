const http = require('http');

const data = JSON.stringify({
  nombre: 'Test User',
  correo: 'testuser@example.com',
  password: 'test1234',
  rol: 'user'
});

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/auth/register',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = http.request(options, res => {
  let body = '';
  res.on('data', chunk => {
    body += chunk;
  });
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Headers:', res.headers);
    console.log('Body:', body);
  });
});

req.on('error', error => {
  console.error('Error de conexión:', error);
});

req.write(data);
req.end(); 