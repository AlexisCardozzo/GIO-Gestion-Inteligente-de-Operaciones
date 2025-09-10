require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function probarRestriccion() {
  const client = await pool.connect();
  try {
    console.log('Iniciando prueba de la nueva restricción...');
    
    // Iniciar transacción
    await client.query('BEGIN');
    
    // Crear dos usuarios de prueba si no existen
    console.log('Verificando/creando usuarios de prueba...');
    const usuariosExistentes = await client.query('SELECT id FROM usuarios WHERE email IN ($1, $2)', ['test1@example.com', 'test2@example.com']);
    
    let usuario1Id, usuario2Id;
    
    if (usuariosExistentes.rows.length < 2) {
      // Si no existen ambos usuarios, los creamos
      if (!usuariosExistentes.rows.find(u => u.email === 'test1@example.com')) {
        const usuario1Result = await client.query(
          'INSERT INTO usuarios (nombre, apellido, email, password_hash, nombre_usuario, rol, activo, creado_en) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW()) RETURNING id',
          ['Usuario', 'Test 1', 'test1@example.com', 'password123', 'usuario_test1', 'admin', true]
        );
        usuario1Id = usuario1Result.rows[0].id;
        console.log(`Usuario 1 creado con ID: ${usuario1Id}`);
      } else {
        usuario1Id = usuariosExistentes.rows.find(u => u.email === 'test1@example.com').id;
        console.log(`Usuario 1 ya existe con ID: ${usuario1Id}`);
      }
      
      if (!usuariosExistentes.rows.find(u => u.email === 'test2@example.com')) {
        const usuario2Result = await client.query(
          'INSERT INTO usuarios (nombre, apellido, email, password_hash, nombre_usuario, rol, activo, creado_en) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW()) RETURNING id',
          ['Usuario', 'Test 2', 'test2@example.com', 'password123', 'usuario_test2', 'admin', true]
        );
        usuario2Id = usuario2Result.rows[0].id;
        console.log(`Usuario 2 creado con ID: ${usuario2Id}`);
      } else {
        usuario2Id = usuariosExistentes.rows.find(u => u.email === 'test2@example.com').id;
        console.log(`Usuario 2 ya existe con ID: ${usuario2Id}`);
      }
    } else {
      // Si ya existen, obtenemos sus IDs
      usuario1Id = usuariosExistentes.rows[0].id;
      usuario2Id = usuariosExistentes.rows[1].id;
      console.log(`Usuarios existentes con IDs: ${usuario1Id} y ${usuario2Id}`);
    }
    
    // Crear una categoría de prueba
    console.log('Creando categoría de prueba...');
    const categoriaResult = await client.query(
      'INSERT INTO categorias (nombre, porcentaje_iva) VALUES ($1, $2) RETURNING id',
      ['Categoría Test', 21]
    );
    const categoriaId = categoriaResult.rows[0].id;
    console.log(`Categoría creada con ID: ${categoriaId}`);
    
    // Eliminar artículos de prueba si existen
    console.log('Eliminando artículos de prueba anteriores...');
    await client.query('DELETE FROM articulos WHERE codigo = $1', ['TEST123']);
    
    // Crear artículo con el mismo código para el usuario 1
    console.log('Creando artículo para usuario 1...');
    const articulo1Result = await client.query(
      'INSERT INTO articulos (nombre, codigo, categoria_id, precio_compra, precio_venta, stock_minimo, activo, creado_en, usuario_id) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), $8) RETURNING id',
      ['Artículo Test 1', 'TEST123', categoriaId, 100, 150, 10, true, usuario1Id]
    );
    console.log(`Artículo 1 creado con ID: ${articulo1Result.rows[0].id}`);
    
    // Crear artículo con el mismo código para el usuario 2
    console.log('Creando artículo para usuario 2...');
    const articulo2Result = await client.query(
      'INSERT INTO articulos (nombre, codigo, categoria_id, precio_compra, precio_venta, stock_minimo, activo, creado_en, usuario_id) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), $8) RETURNING id',
      ['Artículo Test 2', 'TEST123', categoriaId, 200, 250, 5, true, usuario2Id]
    );
    console.log(`Artículo 2 creado con ID: ${articulo2Result.rows[0].id}`);
    
    // Verificar que ambos artículos se crearon correctamente
    const articulosResult = await client.query(
      'SELECT id, nombre, codigo, usuario_id FROM articulos WHERE codigo = $1',
      ['TEST123']
    );
    
    console.log('Artículos creados:');
    articulosResult.rows.forEach(articulo => {
      console.log(`ID: ${articulo.id}, Nombre: ${articulo.nombre}, Código: ${articulo.codigo}, Usuario ID: ${articulo.usuario_id}`);
    });
    
    // Confirmar transacción
    await client.query('COMMIT');
    console.log('✅ Prueba completada exitosamente!');
    console.log('La nueva restricción permite que diferentes usuarios tengan productos con el mismo código.');
  } catch (error) {
    // Revertir cambios en caso de error
    await client.query('ROLLBACK');
    console.error('❌ Error durante la prueba:', error);
  } finally {
    // Liberar cliente
    client.release();
    process.exit(0);
  }
}

probarRestriccion();