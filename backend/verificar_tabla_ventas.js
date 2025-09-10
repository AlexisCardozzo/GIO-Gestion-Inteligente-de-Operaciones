const pool = require('./config/database');

async function verificarTablaVentas() {
  try {
    console.log('🔍 Verificando estructura de la tabla ventas...\n');

    // Verificar si la tabla existe
    const tableExists = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'ventas'
      )
    `);

    if (!tableExists.rows[0].exists) {
      console.log('❌ La tabla ventas no existe');
      return;
    }

    console.log('✅ La tabla ventas existe');

    // Obtener estructura de la tabla
    const structure = await pool.query(`
      SELECT 
        column_name,
        data_type,
        is_nullable,
        column_default
      FROM information_schema.columns 
      WHERE table_name = 'ventas' 
      ORDER BY ordinal_position
    `);

    console.log('\n📋 Estructura de la tabla ventas:');
    structure.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'YES' ? '(NULL)' : '(NOT NULL)'}`);
    });

    // Verificar algunos datos de ejemplo
    const sampleData = await pool.query(`
      SELECT * FROM ventas LIMIT 3
    `);

    console.log('\n📊 Datos de ejemplo:');
    if (sampleData.rows.length > 0) {
      console.log('Columnas disponibles:', Object.keys(sampleData.rows[0]));
      sampleData.rows.forEach((row, index) => {
        console.log(`  Fila ${index + 1}:`, row);
      });
    } else {
      console.log('  No hay datos en la tabla ventas');
    }

  } catch (error) {
    console.error('❌ Error verificando tabla ventas:', error);
  } finally {
    await pool.end();
  }
}

verificarTablaVentas(); 