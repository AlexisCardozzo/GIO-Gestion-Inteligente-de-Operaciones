const { Pool } = require('pg');
require('dotenv').config({ path: './configuracion.env' });

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function agregarColumnaActivo() {
  const client = await pool.connect();
  
  try {
    console.log('🔍 Verificando si la columna "activo" existe en la tabla usuarios...');
    
    // Verificar si la columna existe
    const checkQuery = `
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'usuarios' 
      AND column_name = 'activo'
    `;
    
    const checkResult = await client.query(checkQuery);
    
    if (checkResult.rows.length > 0) {
      console.log('✅ La columna "activo" ya existe en la tabla usuarios');
      return;
    }
    
    console.log('➕ Agregando columna "activo" a la tabla usuarios...');
    
    // Agregar la columna activo
    const alterQuery = `
      ALTER TABLE usuarios 
      ADD COLUMN activo BOOLEAN DEFAULT true
    `;
    
    await client.query(alterQuery);
    
    console.log('✅ Columna "activo" agregada exitosamente');
    
    // Actualizar todos los usuarios existentes como activos
    const updateQuery = `
      UPDATE usuarios 
      SET activo = true 
      WHERE activo IS NULL
    `;
    
    await client.query(updateQuery);
    
    console.log('✅ Todos los usuarios marcados como activos');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

agregarColumnaActivo(); 