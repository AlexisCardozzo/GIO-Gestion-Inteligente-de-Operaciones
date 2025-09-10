const pool = require('../config/database');

async function up() {
  try {
    await pool.query(`
      ALTER TABLE clientes
      ADD COLUMN IF NOT EXISTS usuario_id INTEGER;
    `);
    console.log('Columna usuario_id añadida a la tabla clientes.');
  } catch (error) {
    console.error('Error al añadir la columna usuario_id a clientes:', error);
    throw error;
  }
}

async function down() {
  try {
    await pool.query(`
      ALTER TABLE clientes
      DROP COLUMN IF EXISTS usuario_id;
    `);
    console.log('Columna usuario_id eliminada de la tabla clientes.');
  } catch (error) {
    console.error('Error al eliminar la columna usuario_id de clientes:', error);
    throw error;
  }
}

module.exports = { up, down };