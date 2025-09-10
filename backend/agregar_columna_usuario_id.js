const pool = require('./config/database');

async function agregarColumnaUsuarioId() {
  try {
    // Verificar si la columna ya existe
    const checkColumnQuery = `
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'articulos' AND column_name = 'usuario_id'
    `;
    
    const columnCheck = await pool.query(checkColumnQuery);
    
    if (columnCheck.rows.length === 0) {
      console.log('🔍 La columna usuario_id no existe en la tabla articulos. Agregándola...');
      
      // Agregar la columna usuario_id
      await pool.query(`
        ALTER TABLE articulos 
        ADD COLUMN usuario_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL
      `);
      
      console.log('✅ Columna usuario_id agregada correctamente a la tabla articulos');
      
      // Asignar un usuario por defecto a los productos existentes (usuario admin con ID 1)
      await pool.query(`
        UPDATE articulos 
        SET usuario_id = 1 
        WHERE usuario_id IS NULL
      `);
      
      console.log('✅ Productos existentes actualizados con usuario_id = 1 (admin)');
    } else {
      console.log('✅ La columna usuario_id ya existe en la tabla articulos');
    }
    
    console.log('✅ Proceso completado correctamente');
  } catch (error) {
    console.error('❌ Error al agregar la columna usuario_id:', error);
  } finally {
    // Cerrar la conexión
    pool.end();
  }
}

// Ejecutar la función
agregarColumnaUsuarioId();