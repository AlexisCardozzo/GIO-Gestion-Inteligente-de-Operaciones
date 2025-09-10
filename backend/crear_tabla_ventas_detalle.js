const pool = require('./config/database');

async function crearTablaVentasDetalle() {
  try {
    console.log('🔄 Creando tabla ventas_detalle...\n');

    // Crear tabla ventas_detalle
    await pool.query(`
      CREATE TABLE IF NOT EXISTS ventas_detalle (
        id SERIAL PRIMARY KEY,
        venta_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL DEFAULT 1,
        precio_unitario NUMERIC(10,2) NOT NULL,
        subtotal NUMERIC(10,2) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (venta_id) REFERENCES ventas(id) ON DELETE CASCADE,
        FOREIGN KEY (producto_id) REFERENCES articulos(id) ON DELETE CASCADE
      )
    `);
    console.log('✅ Tabla ventas_detalle creada exitosamente');

    // Crear índices para optimizar consultas
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_ventas_detalle_venta_id ON ventas_detalle(venta_id);
    `);
    console.log('✅ Índice en venta_id creado');

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_ventas_detalle_producto_id ON ventas_detalle(producto_id);
    `);
    console.log('✅ Índice en producto_id creado');

    // Verificar estructura creada
    console.log('\n📋 Verificando estructura de ventas_detalle:');
    const estructura = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'ventas_detalle'
      ORDER BY ordinal_position
    `);
    
    estructura.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    // Verificar restricciones
    console.log('\n🔒 Restricciones de ventas_detalle:');
    const restricciones = await pool.query(`
      SELECT conname, contype, pg_get_constraintdef(oid) as definicion
      FROM pg_constraint
      WHERE conrelid = 'ventas_detalle'::regclass
    `);
    
    restricciones.rows.forEach(restriccion => {
      console.log(`  - ${restriccion.conname} (${restriccion.contype}): ${restriccion.definicion}`);
    });

    console.log('\n🎉 Tabla ventas_detalle creada y configurada correctamente!');
    console.log('✅ La tabla está lista para almacenar detalles de ventas');
    console.log('✅ Los índices están optimizados para consultas rápidas');
    console.log('✅ Las restricciones de integridad referencial están activas');

  } catch (error) {
    console.error('❌ Error creando tabla ventas_detalle:', error);
  } finally {
    await pool.end();
  }
}

crearTablaVentasDetalle(); 