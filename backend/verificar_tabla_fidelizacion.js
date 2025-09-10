const pool = require('./config/database');

async function verificarTablaFidelizacion() {
  try {
    console.log('🔍 Verificando estructura de tabla fidelizacion_campanias...\n');

    const estructura = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'fidelizacion_campanias' 
      ORDER BY ordinal_position
    `);

    console.log('📋 Estructura de la tabla fidelizacion_campanias:');
    estructura.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    // Verificar si hay datos existentes
    const datos = await pool.query('SELECT COUNT(*) as total FROM fidelizacion_campanias');
    console.log(`\n📊 Total de campañas existentes: ${datos.rows[0].total}`);

    if (datos.rows[0].total > 0) {
      const muestras = await pool.query('SELECT id, nombre, activa FROM fidelizacion_campanias LIMIT 5');
      console.log('\n📋 Muestras de campañas existentes:');
      muestras.rows.forEach(row => {
        console.log(`  - ID ${row.id}: ${row.nombre} (activa: ${row.activa})`);
      });
    }

  } catch (error) {
    console.error('❌ Error verificando tabla:', error);
  } finally {
    await pool.end();
  }
}

verificarTablaFidelizacion(); 