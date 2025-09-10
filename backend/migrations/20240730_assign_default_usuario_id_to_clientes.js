const pool = require('../config/database');

async function up() {
  try {
    // Obtener el ID del primer usuario existente para asignarlo por defecto
    const userResult = await pool.query('SELECT id FROM usuarios LIMIT 1');
    const defaultUserId = userResult.rows.length > 0 ? userResult.rows[0].id : null;

    if (defaultUserId) {
      await pool.query(`
        UPDATE clientes
        SET usuario_id = $1
        WHERE usuario_id IS NULL;
      `, [defaultUserId]);
      console.log(`Asignado usuario_id ${defaultUserId} a clientes existentes con usuario_id nulo.`);
    } else {
      console.warn('No se encontraron usuarios para asignar un usuario_id por defecto a los clientes.');
    }
  } catch (error) {
    console.error('Error al asignar usuario_id por defecto a clientes:', error);
    throw error;
  }
}

async function down() {
  // Esta migración no tiene un 'down' significativo ya que asigna un valor por defecto.
  // Si se quisiera revertir, implicaría establecer usuario_id a NULL, lo cual no es deseable.
  console.log('Down migration para asignar usuario_id a clientes no implementada.');
}

module.exports = { up, down };