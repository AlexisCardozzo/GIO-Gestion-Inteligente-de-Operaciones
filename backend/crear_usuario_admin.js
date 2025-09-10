const pool = require('./config/database');
const User = require('./models/User');
const bcrypt = require('bcryptjs');

async function crearUsuarioAdmin() {
  try {
    console.log('🔄 Creando usuario administrador...');

    // 1. Verificar si la tabla usuarios existe
    const tablaExiste = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'usuarios'
      );
    `);

    if (!tablaExiste.rows[0].exists) {
      console.log('📝 Creando tabla usuarios...');
      await User.createTable();
    }

    // 2. Crear usuario administrador
    const userData = {
      nombre: 'Admin',
      apellido: 'Sistema',
      nombre_usuario: 'admin',
      email: 'admin@sistema.com',
      password: 'admin123',
      rol: 'admin'
    };

    // Verificar si ya existe el usuario
    const usuarioExiste = await pool.query('SELECT id FROM usuarios WHERE email = $1', [userData.email]);
    
    if (usuarioExiste.rows.length > 0) {
      console.log(`✅ Usuario administrador ya existe con ID: ${usuarioExiste.rows[0].id}`);
      return usuarioExiste.rows[0].id;
    }

    // Crear el usuario
    const usuario = await User.create(userData);
    console.log(`✅ Usuario administrador creado con ID: ${usuario.id}`);
    return usuario.id;

  } catch (error) {
    console.error('❌ Error creando usuario administrador:', error);
    throw error;
  }
}

async function actualizarTablaArticulos() {
  try {
    console.log('🔄 Verificando tabla articulos...');

    // Verificar si existe la columna usuario_id
    const columnaExiste = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'articulos' 
        AND column_name = 'usuario_id'
      );
    `);

    if (!columnaExiste.rows[0].exists) {
      console.log('📝 Agregando columna usuario_id a la tabla articulos...');
      await pool.query('ALTER TABLE articulos ADD COLUMN usuario_id INTEGER');
      console.log('✅ Columna usuario_id agregada correctamente');
    } else {
      console.log('✅ La columna usuario_id ya existe en la tabla articulos');
    }

  } catch (error) {
    console.error('❌ Error actualizando tabla articulos:', error);
    throw error;
  }
}

async function main() {
  try {
    console.log('🚀 Iniciando configuración del sistema...');
    
    // Crear usuario administrador
    const adminId = await crearUsuarioAdmin();
    
    // Actualizar tabla articulos
    await actualizarTablaArticulos();
    
    // Actualizar registros existentes con el usuario_id del admin
    console.log('🔄 Actualizando registros existentes con el usuario_id del admin...');
    await pool.query('UPDATE articulos SET usuario_id = $1 WHERE usuario_id IS NULL', [adminId]);
    
    console.log('🎉 Configuración completada exitosamente!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error en la configuración:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Ejecutar el script
main();