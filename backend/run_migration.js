const { up } = require('./migrations/20240730_assign_default_usuario_id_to_clientes');

async function runMigration() {
  try {
    await up();
    console.log('Migración ejecutada exitosamente.');
    process.exit(0);
  } catch (error) {
    console.error('Error al ejecutar la migración:', error);
    process.exit(1);
  }
}

runMigration();