const pool = require('./config/database');

async function verificarTablaClientes() {
  try {
    console.log('🔍 Verificando estructura de la tabla clientes...\n');

    // Verificar si la tabla existe
    const tableExists = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'clientes'
      )
    `);

    if (!tableExists.rows[0].exists) {
      console.log('❌ La tabla clientes no existe');
      return;
    }

    console.log('✅ La tabla clientes existe');

    // Obtener estructura de la tabla
    const structure = await pool.query(`
      SELECT 
        column_name,
        data_type,
        is_nullable,
        column_default
      FROM information_schema.columns 
      WHERE table_name = 'clientes' 
      ORDER BY ordinal_position
    `);

    console.log('\n📋 Estructura de la tabla clientes:');
    structure.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'YES' ? '(NULL)' : '(NOT NULL)'}`);
    });

    // Verificar restricciones únicas
    const constraints = await pool.query(`
      SELECT 
        tc.constraint_name,
        tc.constraint_type,
        kcu.column_name
      FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
      WHERE tc.table_name = 'clientes'
      AND tc.constraint_type IN ('UNIQUE', 'PRIMARY KEY')
    `);

    console.log('\n🔒 Restricciones únicas:');
    if (constraints.rows.length > 0) {
      constraints.rows.forEach(constraint => {
        console.log(`  - ${constraint.constraint_name}: ${constraint.constraint_type} en ${constraint.column_name}`);
      });
    } else {
      console.log('  No hay restricciones únicas definidas');
    }

    // Verificar algunos datos de ejemplo
    const sampleData = await pool.query(`
      SELECT * FROM clientes LIMIT 3
    `);

    console.log('\n📊 Datos de ejemplo:');
    if (sampleData.rows.length > 0) {
      console.log('Columnas disponibles:', Object.keys(sampleData.rows[0]));
      sampleData.rows.forEach((row, index) => {
        console.log(`  Fila ${index + 1}:`, row);
      });
    } else {
      console.log('  No hay datos en la tabla clientes');
    }

  } catch (error) {
    console.error('❌ Error verificando tabla clientes:', error);
  } finally {
    await pool.end();
  }
}

verificarTablaClientes(); 