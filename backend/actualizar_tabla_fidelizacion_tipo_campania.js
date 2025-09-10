const pool = require('./config/database');

async function actualizarTablaFidelizacionTipoCampania() {
  try {
    console.log('🔄 Actualizando tabla fidelizacion_campanias con tipo_campania...\n');

    // Agregar columna tipo_campania
    try {
      await pool.query(`
        ALTER TABLE fidelizacion_campanias 
        ADD COLUMN IF NOT EXISTS tipo_campania VARCHAR(50)
      `);
      console.log('✅ Columna tipo_campania agregada/verificada');
    } catch (error) {
      console.log('ℹ️ Columna tipo_campania ya existe');
    }

    // Verificar estructura final
    const estructura = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'fidelizacion_campanias' 
      ORDER BY ordinal_position
    `);

    console.log('\n📋 Estructura final de la tabla fidelizacion_campanias:');
    estructura.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    console.log('\n🎉 Tabla fidelizacion_campanias actualizada exitosamente!');

  } catch (error) {
    console.error('❌ Error actualizando tabla:', error);
  } finally {
    await pool.end();
  }
}

actualizarTablaFidelizacionTipoCampania(); 