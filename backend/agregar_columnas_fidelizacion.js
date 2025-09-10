const pool = require('./config/database');

async function agregarColumnasFidelizacion() {
  try {
    console.log('🔄 Agregando columnas a fidelizacion_clientes...\n');

    // Agregar columnas individualmente
    await pool.query('ALTER TABLE fidelizacion_clientes ADD COLUMN IF NOT EXISTS puntos_actuales INTEGER DEFAULT 0');
    console.log('✅ puntos_actuales agregada');

    await pool.query('ALTER TABLE fidelizacion_clientes ADD COLUMN IF NOT EXISTS total_compras INTEGER DEFAULT 0');
    console.log('✅ total_compras agregada');

    await pool.query('ALTER TABLE fidelizacion_clientes ADD COLUMN IF NOT EXISTS monto_total_gastado NUMERIC(10,2) DEFAULT 0');
    console.log('✅ monto_total_gastado agregada');

    await pool.query('ALTER TABLE fidelizacion_clientes ADD COLUMN IF NOT EXISTS fecha_ultima_compra TIMESTAMP');
    console.log('✅ fecha_ultima_compra agregada');

    // Verificar estructura
    console.log('\n📋 Estructura actualizada:');
    const estructura = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'fidelizacion_clientes'
      ORDER BY ordinal_position
    `);
    
    estructura.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    console.log('\n🎉 Columnas agregadas exitosamente!');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await pool.end();
  }
}

agregarColumnasFidelizacion(); 