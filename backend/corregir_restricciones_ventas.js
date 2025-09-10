const pool = require('./config/database');

async function corregirRestriccionesVentas() {
  try {
    console.log('🔧 Corrigiendo restricciones de clave foránea...\n');

    // 1. Verificar restricciones actuales
    console.log('📋 Restricciones actuales de ventas_detalle:');
    const restricciones = await pool.query(`
      SELECT 
        tc.constraint_name,
        tc.table_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name,
        rc.delete_rule,
        rc.update_rule
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
      JOIN information_schema.referential_constraints AS rc
        ON tc.constraint_name = rc.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND tc.table_name = 'ventas_detalle'
      ORDER BY tc.constraint_name
    `);

    restricciones.rows.forEach(restriccion => {
      console.log(`  - ${restriccion.constraint_name}: ${restriccion.column_name} → ${restriccion.foreign_table_name}.${restriccion.foreign_column_name} (DELETE: ${restriccion.delete_rule})`);
    });

    // 2. Eliminar restricciones existentes
    console.log('\n🗑️ Eliminando restricciones existentes...');
    
    for (const restriccion of restricciones.rows) {
      try {
        await pool.query(`ALTER TABLE ventas_detalle DROP CONSTRAINT ${restriccion.constraint_name}`);
        console.log(`  ✅ Eliminada restricción: ${restriccion.constraint_name}`);
      } catch (error) {
        console.log(`  ⚠️ Error eliminando ${restriccion.constraint_name}: ${error.message}`);
      }
    }

    // 3. Crear nuevas restricciones sin CASCADE
    console.log('\n🔧 Creando nuevas restricciones...');
    
    // Restricción para venta_id (mantener CASCADE para ventas)
    try {
      await pool.query(`
        ALTER TABLE ventas_detalle 
        ADD CONSTRAINT fk_ventas_detalle_venta_id 
        FOREIGN KEY (venta_id) REFERENCES ventas(id) ON DELETE CASCADE
      `);
      console.log('  ✅ Restricción venta_id creada (CASCADE)');
    } catch (error) {
      console.log(`  ⚠️ Error creando restricción venta_id: ${error.message}`);
    }

    // Restricción para producto_id (SIN CASCADE para preservar historial)
    try {
      await pool.query(`
        ALTER TABLE ventas_detalle 
        ADD CONSTRAINT fk_ventas_detalle_producto_id 
        FOREIGN KEY (producto_id) REFERENCES articulos(id) ON DELETE RESTRICT
      `);
      console.log('  ✅ Restricción producto_id creada (RESTRICT)');
    } catch (error) {
      console.log(`  ⚠️ Error creando restricción producto_id: ${error.message}`);
    }

    // 4. Verificar restricciones finales
    console.log('\n📋 Restricciones finales de ventas_detalle:');
    const restriccionesFinales = await pool.query(`
      SELECT 
        tc.constraint_name,
        tc.table_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name,
        rc.delete_rule,
        rc.update_rule
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
      JOIN information_schema.referential_constraints AS rc
        ON tc.constraint_name = rc.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND tc.table_name = 'ventas_detalle'
      ORDER BY tc.constraint_name
    `);

    restriccionesFinales.rows.forEach(restriccion => {
      console.log(`  - ${restriccion.constraint_name}: ${restriccion.column_name} → ${restriccion.foreign_table_name}.${restriccion.foreign_column_name} (DELETE: ${restriccion.delete_rule})`);
    });

    console.log('\n✅ Restricciones corregidas exitosamente!');
    console.log('💡 Ahora al eliminar un producto:');
    console.log('   - Se preservarán los registros de ventas');
    console.log('   - Se mantendrá el historial de ventas');
    console.log('   - Los totales vendidos no se afectarán');

  } catch (error) {
    console.error('❌ Error durante la corrección:', error);
  } finally {
    await pool.end();
  }
}

corregirRestriccionesVentas();
