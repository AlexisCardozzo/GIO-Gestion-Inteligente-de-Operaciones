const pool = require('./config/database');
const Cliente = require('./models/Cliente');

async function testCrearCliente() {
  try {
    console.log('🧪 Probando creación de clientes...\n');

    // Obtener un usuario válido para la prueba
    console.log('👤 Obteniendo usuario para la prueba...');
    const usuarios = await pool.query('SELECT id FROM usuarios LIMIT 1');
    const usuarioId = usuarios.rows.length > 0 ? usuarios.rows[0].id : 1;
    console.log(`✅ Usuario seleccionado: ID ${usuarioId}`);

    // Test 1: Crear cliente con ci_ruc
    console.log('1️⃣ Creando cliente con ci_ruc...');
    const cliente1 = await Cliente.crear({
      ci_ruc: '12345678',
      nombre: 'Juan Pérez',
      celular: '0981123456',
      usuario_id: usuarioId
    });
    console.log(`✅ Cliente creado: ID ${cliente1.id}, Nombre: ${cliente1.nombre}, CI/RUC: ${cliente1.ci_ruc}`);

    // Test 2: Crear cliente sin ci_ruc (debe generar identificador)
    console.log('\n2️⃣ Creando cliente sin ci_ruc...');
    const cliente2 = await Cliente.crear({
      nombre: 'María García',
      celular: '0998765432',
      usuario_id: usuarioId
    });
    console.log(`✅ Cliente creado: ID ${cliente2.id}, Nombre: ${cliente2.nombre}, Identificador: ${cliente2.identificador}`);

    // Test 3: Crear cliente con ci_ruc null
    console.log('\n3️⃣ Creando cliente con ci_ruc null...');
    const cliente3 = await Cliente.crear({
      ci_ruc: null,
      nombre: 'Carlos López',
      celular: '0971122334',
      usuario_id: usuarioId
    });
    console.log(`✅ Cliente creado: ID ${cliente3.id}, Nombre: ${cliente3.nombre}, Identificador: ${cliente3.identificador}`);

    // Verificar todos los clientes creados
    console.log('\n📊 Verificando clientes creados...');
    const todosLosClientes = await pool.query(`
      SELECT id, nombre, ci_ruc, identificador, celular, activo 
      FROM clientes 
      ORDER BY id DESC 
      LIMIT 3
    `);

    console.log('\n📋 Clientes en la base de datos:');
    todosLosClientes.rows.forEach((cliente, index) => {
      console.log(`  Cliente ${index + 1}: ID ${cliente.id}, Nombre: ${cliente.nombre}, CI/RUC: ${cliente.ci_ruc || 'N/A'}, Identificador: ${cliente.identificador || 'N/A'}`);
    });

    console.log('\n🎉 ¡Pruebas completadas exitosamente!');
    console.log('✅ La creación de clientes funciona correctamente');

  } catch (error) {
    console.error('❌ Error durante las pruebas:', error);
  } finally {
    await pool.end();
  }
}

testCrearCliente();
