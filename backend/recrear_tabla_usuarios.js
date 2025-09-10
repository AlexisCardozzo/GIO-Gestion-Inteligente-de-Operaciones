const pool = require('./config/database');

async function recrearTablaUsuarios() {
  try {
    // Eliminar la tabla existente si existe
    await pool.query('DROP TABLE IF EXISTS usuarios CASCADE');
    console.log('✅ Tabla usuarios eliminada');

    // Crear la tabla con la estructura correcta
    const createTableQuery = `
      CREATE TABLE usuarios (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        apellido VARCHAR(100) NOT NULL,
        nombre_usuario VARCHAR(100) UNIQUE NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        rol VARCHAR(20) DEFAULT 'user',
        activo BOOLEAN DEFAULT true,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;
    
    await pool.query(createTableQuery);
    console.log('✅ Tabla usuarios recreada con la estructura correcta');
    
  } catch (error) {
    console.error('❌ Error recreando tabla usuarios:', error);
  } finally {
    await pool.end();
  }
}

recrearTablaUsuarios(); 