const pool = require('./config/database');

async function verificarEstructuraVentas() {
  try {
    console.log('🔍 Verificando estructura de tablas de ventas...\n');

    // 1. Listar todas las tablas
    console.log('📋 Tablas existentes en la base de datos:');
    const tablas = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);
    
    tablas.rows.forEach(tabla => {
      console.log(`  - ${tabla.table_name}`);
    });

    // 2. Verificar estructura de tabla ventas
    console.log('\n📋 Estructura detallada de tabla ventas:');
    const estructuraVentas = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable, character_maximum_length
      FROM information_schema.columns
      WHERE table_name = 'ventas'
      ORDER BY ordinal_position
    `);
    
    estructuraVentas.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type}${col.character_maximum_length ? `(${col.character_maximum_length})` : ''} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    // 3. Verificar si existe tabla ventas_detalle
    console.log('\n🔍 Verificando tabla ventas_detalle...');
    const existeVentasDetalle = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'ventas_detalle'
      )
    `);
    
    if (existeVentasDetalle.rows[0].exists) {
      console.log('✅ Tabla ventas_detalle existe');
      
      const estructuraDetalle = await pool.query(`
        SELECT column_name, data_type, column_default, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'ventas_detalle'
        ORDER BY ordinal_position
      `);
      
      console.log('Estructura de ventas_detalle:');
      estructuraDetalle.rows.forEach(col => {
        console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
      });
    } else {
      console.log('❌ Tabla ventas_detalle NO existe');
    }

    // 4. Verificar datos de ejemplo en ventas
    console.log('\n📊 Datos de ejemplo en tabla ventas:');
    const ventasEjemplo = await pool.query(`
      SELECT id, fecha, total, forma_pago, numero_factura
      FROM ventas
      ORDER BY fecha DESC
      LIMIT 5
    `);
    
    if (ventasEjemplo.rows.length > 0) {
      ventasEjemplo.rows.forEach(venta => {
        console.log(`  - ID: ${venta.id}, Fecha: ${venta.fecha}, Total: ${venta.total}, Método: ${venta.forma_pago || 'N/A'}, Factura: ${venta.numero_factura || 'N/A'}`);
      });
    } else {
      console.log('  - No hay ventas registradas');
    }

    // 5. Verificar restricciones de forma_pago
    console.log('\n🔒 Verificando restricciones de forma_pago...');
    const restricciones = await pool.query(`
      SELECT conname, contype, pg_get_constraintdef(oid) as definicion
      FROM pg_constraint
      WHERE conrelid = 'ventas'::regclass
    `);
    
    if (restricciones.rows.length > 0) {
      restricciones.rows.forEach(restriccion => {
        console.log(`  - ${restriccion.conname} (${restriccion.contype}): ${restriccion.definicion}`);
      });
    } else {
      console.log('  - No hay restricciones definidas');
    }

  } catch (error) {
    console.error('❌ Error verificando estructura:', error);
  } finally {
    await pool.end();
  }
}

verificarEstructuraVentas(); 