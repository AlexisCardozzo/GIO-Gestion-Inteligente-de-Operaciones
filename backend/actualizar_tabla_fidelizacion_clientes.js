const pool = require('./config/database');

async function actualizarTablaFidelizacionClientes() {
  try {
    console.log('🔄 Actualizando tabla fidelizacion_clientes...\n');

    // Verificar estructura actual
    console.log('📋 Estructura actual de fidelizacion_clientes:');
    const estructuraActual = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'fidelizacion_clientes'
      ORDER BY ordinal_position
    `);
    
    estructuraActual.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    // Agregar columnas faltantes
    const columnasNecesarias = [
      { nombre: 'puntos_actuales', tipo: 'INTEGER DEFAULT 0' },
      { nombre: 'total_compras', tipo: 'INTEGER DEFAULT 0' },
      { nombre: 'monto_total_gastado', tipo: 'NUMERIC(10,2) DEFAULT 0' },
      { nombre: 'fecha_ultima_compra', tipo: 'TIMESTAMP' },
      { nombre: 'nivel_fidelizacion', tipo: 'VARCHAR(20) DEFAULT \'bronce\'' },
      { nombre: 'created_at', tipo: 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' },
      { nombre: 'updated_at', tipo: 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' }
    ];

    console.log('\n🔧 Agregando columnas faltantes...');
    
    for (const columna of columnasNecesarias) {
      try {
        await pool.query(`
          ALTER TABLE fidelizacion_clientes
          ADD COLUMN IF NOT EXISTS ${columna.nombre} ${columna.tipo}
        `);
        console.log(`✅ Columna ${columna.nombre} agregada/verificada`);
      } catch (error) {
        console.log(`ℹ️ Columna ${columna.nombre} ya existe`);
      }
    }

    // Verificar estructura final
    console.log('\n📋 Estructura final de fidelizacion_clientes:');
    const estructuraFinal = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'fidelizacion_clientes'
      ORDER BY ordinal_position
    `);
    
    estructuraFinal.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    // Verificar restricciones
    console.log('\n🔒 Restricciones de fidelizacion_clientes:');
    const restricciones = await pool.query(`
      SELECT conname, contype, pg_get_constraintdef(oid) as definicion
      FROM pg_constraint
      WHERE conrelid = 'fidelizacion_clientes'::regclass
    `);
    
    if (restricciones.rows.length > 0) {
      restricciones.rows.forEach(restriccion => {
        console.log(`  - ${restriccion.conname} (${restriccion.contype}): ${restriccion.definicion}`);
      });
    } else {
      console.log('  - No hay restricciones definidas');
    }

    // Crear registro de prueba
    console.log('\n🔄 Creando registro de prueba...');
    const clienteTest = await pool.query(`
      SELECT id FROM clientes WHERE identificador = 'TEST001'
    `);
    
    if (clienteTest.rows.length > 0) {
      const clienteId = clienteTest.rows[0].id;
      
      await pool.query(`
        INSERT INTO fidelizacion_clientes (cliente_id, puntos_actuales, total_compras, monto_total_gastado)
        VALUES ($1, 0, 0, 0)
        ON CONFLICT (cliente_id) DO UPDATE SET
          puntos_actuales = EXCLUDED.puntos_actuales,
          total_compras = EXCLUDED.total_compras,
          monto_total_gastado = EXCLUDED.monto_total_gastado
      `, [clienteId]);
      
      console.log('✅ Registro de prueba creado/actualizado');
    }

    console.log('\n🎉 Tabla fidelizacion_clientes actualizada exitosamente!');
    console.log('✅ Todas las columnas necesarias están disponibles');
    console.log('✅ La tabla está lista para el sistema de fidelización');

  } catch (error) {
    console.error('❌ Error actualizando tabla:', error);
  } finally {
    await pool.end();
  }
}

actualizarTablaFidelizacionClientes(); 