const pool = require('./config/database');

async function actualizarTablaClientesRiesgo() {
  try {
    console.log('🔄 Actualizando tabla clientes_riesgo con nuevas columnas...\n');

    // Agregar nuevas columnas para información personalizada
    const nuevasColumnas = [
      'total_compras INTEGER',
      'promedio_compra DECIMAL(10,2)',
      'total_gastado DECIMAL(10,2)',
      'tipo_cliente VARCHAR(50)',
      'valor_cliente VARCHAR(50)'
    ];

    for (const columna of nuevasColumnas) {
      const [nombreColumna] = columna.split(' ');
      try {
        await pool.query(`ALTER TABLE clientes_riesgo ADD COLUMN IF NOT EXISTS ${columna}`);
        console.log(`✅ Columna ${nombreColumna} agregada/verificada`);
      } catch (error) {
        console.log(`ℹ️ Columna ${nombreColumna} ya existe`);
      }
    }

    // Verificar estructura final
    const estructura = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'clientes_riesgo' 
      ORDER BY ordinal_position
    `);

    console.log('\n📋 Estructura final de la tabla clientes_riesgo:');
    estructura.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type}`);
    });

    console.log('\n🎉 Tabla clientes_riesgo actualizada exitosamente!');
    console.log('💡 Ahora puede almacenar información detallada para mensajes personalizados');

  } catch (error) {
    console.error('❌ Error actualizando tabla:', error);
  } finally {
    await pool.end();
  }
}

actualizarTablaClientesRiesgo(); 