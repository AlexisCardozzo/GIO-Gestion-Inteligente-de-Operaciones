const pool = require('../config/database');

module.exports = {
  up: async () => {
    const client = await pool.connect();
    try {
      await client.query(`
        CREATE TABLE IF NOT EXISTS movimientos_stock (
          id SERIAL PRIMARY KEY,
          articulo_id INTEGER NOT NULL REFERENCES articulos(id) ON DELETE CASCADE,
          tipo_movimiento VARCHAR(50) NOT NULL, -- 'entrada' o 'salida'
          cantidad INTEGER NOT NULL,
          stock_antes INTEGER NOT NULL,
          stock_despues INTEGER NOT NULL,
          referencia TEXT,
          fecha_hora TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);
      console.log('Tabla movimientos_stock creada o verificada.');
    } finally {
      client.release();
    }
  },
  down: async () => {
    const client = await pool.connect();
    try {
      await client.query('DROP TABLE IF EXISTS movimientos_stock;');
      console.log('Tabla movimientos_stock eliminada.');
    } finally {
      client.release();
    }
  },
};