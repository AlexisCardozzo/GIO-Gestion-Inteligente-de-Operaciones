const pool = require('./config/database');

async function actualizarFidelizacionSimple() {
  try {
    console.log('🔄 Actualizando tabla fidelizacion_clientes...\n');

    // Agregar columnas una por una
    const columnas = [
      'ADD COLUMN IF NOT EXISTS puntos_actuales INTEGER DEFAULT 0',
      'ADD COLUMN IF NOT EXISTS total_compras INTEGER DEFAULT 0',
      'ADD COLUMN IF NOT EXISTS monto_total_gastado NUMERIC(10,2) DEFAULT 0',
      'ADD COLUMN IF NOT EXISTS fecha_ultima_compra TIMESTAMP'
    ];

    for (const columna of columnas) {
      try {
        await pool.query(`ALTER TABLE fidelizacion_clientes ${columna}`);
        console.log(`✅ Columna agregada: ${columna.split(' ')[3]}`);
      } catch (error) {
        console.log(`ℹ️ Columna ya existe: ${columna.split(' ')[3]}`);
      }
    }

    // Verificar estructura final
    console.log('\n📋 Estructura final:');
    const estructura = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'fidelizacion_clientes'
      ORDER BY ordinal_position
    `);
    
    estructura.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    console.log('\n🎉 Tabla actualizada exitosamente!');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await pool.end();
  }
}

actualizarFidelizacionSimple(); 