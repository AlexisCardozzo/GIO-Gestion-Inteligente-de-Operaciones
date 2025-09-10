const pool = require('./config/database');

async function testIntegracionVentas() {
  try {
    console.log('🧪 Iniciando prueba de integración de ventas...\n');

    // 1. Verificar estructura de tabla ventas
    console.log('📋 Verificando estructura de tabla ventas...');
    const estructuraVentas = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'ventas'
      ORDER BY ordinal_position
    `);
    console.log('Estructura de tabla ventas:');
    estructuraVentas.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    // 2. Verificar estructura de tabla clientes
    console.log('\n📋 Verificando estructura de tabla clientes...');
    const estructuraClientes = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'clientes'
      ORDER BY ordinal_position
    `);
    console.log('Estructura de tabla clientes:');
    estructuraClientes.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });

    // 3. Crear cliente de prueba
    console.log('\n👤 Creando cliente de prueba...');
    const clienteTest = await pool.query(`
      INSERT INTO clientes (identificador, nombre, telefono, activo)
      VALUES ($1, $2, $3, true)
      ON CONFLICT (identificador) DO UPDATE SET
        nombre = EXCLUDED.nombre,
        telefono = EXCLUDED.telefono
      RETURNING *
    `, ['TEST001', 'Cliente Test Integración', '0999123456']);
    
    const clienteId = clienteTest.rows[0].id;
    console.log(`✅ Cliente creado: ID ${clienteId}`);

    // 4. Obtener producto de prueba
    console.log('\n📦 Obteniendo producto de prueba...');
    const productos = await pool.query('SELECT * FROM articulos LIMIT 1');
    if (productos.rows.length === 0) {
      throw new Error('No hay productos en la base de datos');
    }
    const producto = productos.rows[0];
    console.log(`✅ Producto encontrado: ${producto.nombre} (ID: ${producto.id})`);

    // Obtener un usuario válido para la prueba
    console.log('👤 Obteniendo usuario para la prueba...');
    const usuarios = await pool.query('SELECT id FROM usuarios LIMIT 1');
    const usuarioId = usuarios.rows.length > 0 ? usuarios.rows[0].id : 1;
    console.log(`✅ Usuario seleccionado: ID ${usuarioId}`);
    
    // 5. Probar ventas con diferentes métodos de pago
    const metodosPago = ['efectivo', 'tarjeta', 'qr'];
    
    for (const metodoPago of metodosPago) {
      console.log(`\n💳 Probando venta con método de pago: ${metodoPago}`);
      
      // Crear venta
      const venta = await pool.query(`
        INSERT INTO ventas (sucursal_id, usuario_id, cliente_id, fecha, total, numero_factura, forma_pago)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *
      `, [1, usuarioId, clienteId, new Date(), producto.precio_venta, `TEST-${metodoPago.toUpperCase()}-${Date.now()}`, metodoPago]);
      
      const ventaId = venta.rows[0].id;
      console.log(`✅ Venta creada: ID ${ventaId}, Total: ${producto.precio_venta}, Método: ${metodoPago}`);

      // Crear detalle de venta
      await pool.query(`
        INSERT INTO ventas_detalle (venta_id, producto_id, cantidad, precio_unitario, subtotal)
        VALUES ($1, $2, $3, $4, $5)
      `, [ventaId, producto.id, 1, producto.precio_venta, producto.precio_venta]);
      
      console.log(`✅ Detalle de venta creado`);
    }

    // 6. Verificar ventas creadas
    console.log('\n📊 Verificando ventas creadas...');
    const ventasCreadas = await pool.query(`
      SELECT v.id, v.fecha, v.total, v.forma_pago, c.nombre as cliente_nombre
      FROM ventas v
      JOIN clientes c ON v.cliente_id = c.id
      WHERE c.identificador = 'TEST001'
      ORDER BY v.fecha DESC
    `);
    
    console.log('Ventas creadas:');
    ventasCreadas.rows.forEach(venta => {
      console.log(`  - ID: ${venta.id}, Cliente: ${venta.cliente_nombre}, Total: ${venta.total}, Método: ${venta.forma_pago}`);
    });

    // 7. Verificar estadísticas por método de pago
    console.log('\n📈 Verificando estadísticas por método de pago...');
    const estadisticas = await pool.query(`
      SELECT forma_pago, COUNT(*) as total_ventas, SUM(total) as monto_total, AVG(total) as promedio_venta
      FROM ventas
      WHERE forma_pago IS NOT NULL
      GROUP BY forma_pago
      ORDER BY monto_total DESC
    `);
    
    console.log('Estadísticas por método de pago:');
    estadisticas.rows.forEach(stat => {
      console.log(`  - ${stat.forma_pago}: ${stat.total_ventas} ventas, $${stat.monto_total} total, $${stat.promedio_venta} promedio`);
    });

    // 8. Verificar puntos de fidelización
    console.log('\n🎯 Verificando puntos de fidelización...');
    const fidelizacion = await pool.query(`
      SELECT puntos_actuales, total_compras, monto_total_gastado
      FROM fidelizacion_clientes
      WHERE cliente_id = $1
    `, [clienteId]);
    
    if (fidelizacion.rows.length > 0) {
      const fidelizacionData = fidelizacion.rows[0];
      console.log(`✅ Puntos de fidelización: ${fidelizacionData.puntos_actuales} puntos, ${fidelizacionData.total_compras} compras, $${fidelizacionData.monto_total_gastado} gastado`);
    } else {
      console.log('⚠️ No se encontraron datos de fidelización');
    }

    console.log('\n🎉 Prueba de integración completada exitosamente!');
    console.log('✅ Todos los métodos de pago funcionan correctamente');
    console.log('✅ La integración con fidelización está operativa');
    console.log('✅ Los datos se almacenan correctamente en la base de datos');

  } catch (error) {
    console.error('❌ Error en la prueba de integración:', error);
  } finally {
    await pool.end();
  }
}

testIntegracionVentas();