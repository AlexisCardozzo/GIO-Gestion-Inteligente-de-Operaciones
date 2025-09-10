const pool = require('./config/database');

async function actualizarTablaVentasFormaPago() {
  try {
    console.log('🔄 Actualizando tabla ventas con forma de pago...\n');

    // Agregar columna forma_pago
    try {
      await pool.query(`
        ALTER TABLE ventas 
        ADD COLUMN IF NOT EXISTS forma_pago VARCHAR(20) DEFAULT 'efectivo'
      `);
      console.log('✅ Columna forma_pago agregada/verificada');
    } catch (error) {
      console.log('ℹ️ Columna forma_pago ya existe');
    }

    // Agregar constraint para validar formas de pago válidas
    try {
      await pool.query(`
        ALTER TABLE ventas 
        ADD CONSTRAINT check_forma_pago 
        CHECK (forma_pago IN ('efectivo', 'tarjeta', 'qr'))
      `);
      console.log('✅ Constraint de forma_pago agregado/verificado');
    } catch (error) {
      console.log('ℹ️ Constraint de forma_pago ya existe');
    }

    // Verificar estructura final
    const estructura = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'ventas' 
      ORDER BY ordinal_position
    `);

    console.log('\n📋 Estructura final de la tabla ventas:');
    estructura.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    console.log('\n🎉 Tabla ventas actualizada exitosamente!');
    console.log('💡 Formas de pago disponibles: efectivo, tarjeta, qr');

  } catch (error) {
    console.error('❌ Error actualizando tabla:', error);
  } finally {
    await pool.end();
  }
}

actualizarTablaVentasFormaPago(); 