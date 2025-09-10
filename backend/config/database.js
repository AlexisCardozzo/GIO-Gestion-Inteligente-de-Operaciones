require('dotenv').config({ path: 'configuracion.env' });
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20, // Máximo número de conexiones
  min: 2,  // Mínimo número de conexiones
  idleTimeoutMillis: 300000, // 5 minutos
  connectionTimeoutMillis: 10000, // 10 segundos
  acquireTimeoutMillis: 10000, // 10 segundos
  reapIntervalMillis: 1000, // 1 segundo
  createTimeoutMillis: 10000, // 10 segundos
  destroyTimeoutMillis: 5000, // 5 segundos
});

// Manejo de errores del pool
pool.on('error', (err) => {
  console.error('Error inesperado en el pool de conexiones:', err);
});

pool.on('connect', () => {
  console.log('Nueva conexión establecida con la base de datos');
});

module.exports = pool; 