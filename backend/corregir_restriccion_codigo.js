require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function corregirRestriccionCodigo() {
  const client = await pool.connect();
  try {
    console.log('Iniciando corrección de restricción de código en tabla articulos...');
    
    // Iniciar transacción
    await client.query('BEGIN');
    
    // 1. Eliminar la restricción única existente
    console.log('Eliminando restricción única existente...');
    await client.query('ALTER TABLE articulos DROP CONSTRAINT IF EXISTS articulos_codigo_key');
    
    // 2. Crear una nueva restricción única que considere tanto el código como el usuario_id
    console.log('Creando nueva restricción única que considera código y usuario_id...');
    await client.query('ALTER TABLE articulos ADD CONSTRAINT articulos_codigo_usuario_key UNIQUE (codigo, usuario_id)');
    
    // Permitir que el código sea NULL (algunos productos pueden no tener código)
    console.log('Asegurando que el campo código pueda ser NULL...');
    await client.query('ALTER TABLE articulos ALTER COLUMN codigo DROP NOT NULL');
    
    // Confirmar transacción
    await client.query('COMMIT');
    console.log('✅ Corrección completada exitosamente!');
    console.log('Ahora cada usuario puede tener productos con el mismo código que otros usuarios.');
  } catch (error) {
    // Revertir cambios en caso de error
    await client.query('ROLLBACK');
    console.error('❌ Error al corregir la restricción:', error);
  } finally {
    // Liberar cliente
    client.release();
    process.exit(0);
  }
}

corregirRestriccionCodigo();