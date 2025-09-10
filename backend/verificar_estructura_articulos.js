const { Pool } = require('pg');
require('dotenv').config({ path: './configuracion.env' });

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function verificarEstructuraArticulos() {
  const client = await pool.connect();
  
  try {
    console.log('🔍 Verificando estructura de la tabla articulos...');
    
    // Verificar columnas de la tabla articulos
    const columnasQuery = `
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'articulos'
      ORDER BY ordinal_position
    `;
    
    const columnasResult = await client.query(columnasQuery);
    console.log('📋 Columnas de la tabla articulos:');
    columnasResult.rows.forEach(col => {
      console.log(`   - ${col.column_name}: ${col.data_type} (${col.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });
    
    // Verificar algunos registros de ejemplo
    const registrosQuery = 'SELECT * FROM articulos LIMIT 3';
    const registrosResult = await client.query(registrosQuery);
    
    console.log('\n📊 Registros de ejemplo:');
    registrosResult.rows.forEach((row, index) => {
      console.log(`   Registro ${index + 1}:`, row);
    });
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

verificarEstructuraArticulos(); 