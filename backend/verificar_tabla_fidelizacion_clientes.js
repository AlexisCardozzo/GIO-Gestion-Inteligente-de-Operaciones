const pool = require('./config/database');

async function verificarTablaFidelizacionClientes() {
  try {
    console.log('🔍 Verificando tabla fidelizacion_clientes...\n');

    // Verificar si existe la tabla
    const existeTabla = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'fidelizacion_clientes'
      )
    `);
    
    if (!existeTabla.rows[0].exists) {
      console.log('❌ Tabla fidelizacion_clientes NO existe');
      console.log('🔄 Creando tabla fidelizacion_clientes...');
      
      await pool.query(`
        CREATE TABLE fidelizacion_clientes (
          id SERIAL PRIMARY KEY,
          cliente_id INTEGER NOT NULL UNIQUE,
          puntos_actuales INTEGER DEFAULT 0,
          total_compras INTEGER DEFAULT 0,
          monto_total_gastado NUMERIC(10,2) DEFAULT 0,
          fecha_ultima_compra TIMESTAMP,
          nivel_fidelizacion VARCHAR(20) DEFAULT 'bronce',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
        )
      `);
      
      console.log('✅ Tabla fidelizacion_clientes creada exitosamente');
    } else {
      console.log('✅ Tabla fidelizacion_clientes existe');
    }

    // Verificar estructura
    console.log('\n📋 Estructura de fidelizacion_clientes:');
    const estructura = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'fidelizacion_clientes'
      ORDER BY ordinal_position
    `);
    
    estructura.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    // Verificar datos existentes
    console.log('\n📊 Datos existentes en fidelizacion_clientes:');
    const datos = await pool.query(`
      SELECT fc.*, c.nombre as cliente_nombre
      FROM fidelizacion_clientes fc
      JOIN clientes c ON fc.cliente_id = c.id
      ORDER BY fc.puntos_actuales DESC
      LIMIT 5
    `);
    
    if (datos.rows.length > 0) {
      datos.rows.forEach(row => {
        console.log(`  - Cliente: ${row.cliente_nombre}, Puntos: ${row.puntos_actuales}, Compras: ${row.total_compras}, Total: $${row.monto_total_gastado}`);
      });
    } else {
      console.log('  - No hay datos de fidelización registrados');
    }

    // Crear registro de prueba si no existe
    console.log('\n🔄 Creando registro de prueba...');
    const clienteTest = await pool.query(`
      SELECT id FROM clientes WHERE identificador = 'TEST001'
    `);
    
    if (clienteTest.rows.length > 0) {
      const clienteId = clienteTest.rows[0].id;
      
      await pool.query(`
        INSERT INTO fidelizacion_clientes (cliente_id, puntos_actuales, total_compras, monto_total_gastado)
        VALUES ($1, 0, 0, 0)
        ON CONFLICT (cliente_id) DO NOTHING
      `, [clienteId]);
      
      console.log('✅ Registro de prueba creado/verificado');
    }

  } catch (error) {
    console.error('❌ Error verificando fidelización:', error);
  } finally {
    await pool.end();
  }
}

verificarTablaFidelizacionClientes(); 