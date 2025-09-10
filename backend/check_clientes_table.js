const pool = require('./config/database');

async function checkClientesTable() {
  try {
    const result = await pool.query('SELECT column_name FROM information_schema.columns WHERE table_name = \'clientes\'');
    console.log('Columnas de la tabla clientes:');
    result.rows.forEach(row => {
      console.log(`- ${row.column_name}`);
    });
  } catch (error) {
    console.error('Error al consultar la estructura de la tabla:', error);
  } finally {
    process.exit();
  }
}

checkClientesTable();