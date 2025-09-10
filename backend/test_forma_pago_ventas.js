const pool = require('./config/database');

async function testFormaPagoVentas() {
  try {
    console.log('🧪 Probando ventas con diferentes formas de pago...\n');

    // Crear un cliente de prueba
    const clienteQuery = `
      INSERT INTO clientes (nombre, identificador, telefono) 
      VALUES ($1, $2, $3) 
      ON CONFLICT (identificador) DO UPDATE SET 
        nombre = EXCLUDED.nombre,
        telefono = EXCLUDED.telefono
      RETURNING id
    `;
    
    const clienteResult = await pool.query(clienteQuery, [
      'Cliente Test Forma Pago',
      '12345678',
      '0981123456'
    ]);
    
    const clienteId = clienteResult.rows[0].id;
    console.log(`✅ Cliente creado/actualizado: ID ${clienteId}`);

    // Obtener un producto existente
    const productoQuery = 'SELECT id, nombre, precio_venta FROM articulos LIMIT 1';
    const productoResult = await pool.query(productoQuery);
    
    if (productoResult.rows.length === 0) {
      console.log('❌ No hay productos disponibles para la prueba');
      return;
    }
    
    const producto = productoResult.rows[0];
    console.log(`✅ Producto seleccionado: ${producto.nombre} ($${producto.precio_venta})`);

    // Probar ventas con diferentes formas de pago
    const formasPago = ['efectivo', 'tarjeta', 'qr'];
    
    for (const formaPago of formasPago) {
      console.log(`\n🔄 Probando venta con forma de pago: ${formaPago.toUpperCase()}`);
      
      const ventaQuery = `
        INSERT INTO ventas (sucursal_id, usuario_id, cliente_id, total, forma_pago) 
        VALUES ($1, $2, $3, $4, $5) 
        RETURNING id, total, forma_pago, fecha
      `;
      
      const ventaResult = await pool.query(ventaQuery, [
        1, // sucursal_id
        1, // usuario_id
        clienteId,
        producto.precio_venta,
        formaPago
      ]);
      
      const venta = ventaResult.rows[0];
      console.log(`✅ Venta registrada:`);
      console.log(`   - ID: ${venta.id}`);
      console.log(`   - Total: $${venta.total}`);
      console.log(`   - Forma de Pago: ${venta.forma_pago}`);
      console.log(`   - Fecha: ${venta.fecha}`);
      
      // Registrar detalle de la venta
      const detalleQuery = `
        INSERT INTO detalle_ventas (venta_id, producto_id, cantidad, precio_unitario, subtotal) 
        VALUES ($1, $2, $3, $4, $5)
      `;
      
      await pool.query(detalleQuery, [
        venta.id,
        producto.id,
        1, // cantidad
        producto.precio_venta,
        producto.precio_venta // subtotal
      ]);
      
      console.log(`✅ Detalle de venta registrado`);
    }

    // Verificar ventas registradas
    console.log('\n📊 Verificando ventas registradas:');
    const ventasQuery = `
      SELECT v.id, v.total, v.forma_pago, v.fecha, c.nombre as cliente_nombre
      FROM ventas v
      LEFT JOIN clientes c ON v.cliente_id = c.id
      WHERE v.cliente_id = $1
      ORDER BY v.fecha DESC
    `;
    
    const ventasResult = await pool.query(ventasQuery, [clienteId]);
    
    ventasResult.rows.forEach((venta, index) => {
      console.log(`   ${index + 1}. Venta #${venta.id} - $${venta.total} (${venta.forma_pago}) - ${venta.fecha}`);
    });

    console.log('\n🎉 Prueba completada exitosamente!');
    console.log('💡 Las formas de pago están funcionando correctamente');

  } catch (error) {
    console.error('❌ Error en la prueba:', error);
  } finally {
    await pool.end();
  }
}

testFormaPagoVentas(); 