const pool = require('./config/database');

async function testVentaCompleta() {
  try {
    console.log('🧪 Probando flujo completo de venta...\n');

    // 1. Crear cliente de prueba
    console.log('👤 Creando cliente de prueba...');
    const clienteTest = await pool.query(`
      INSERT INTO clientes (identificador, nombre, telefono, activo)
      VALUES ($1, $2, $3, true)
      ON CONFLICT (identificador) DO UPDATE SET
        nombre = EXCLUDED.nombre,
        telefono = EXCLUDED.telefono
      RETURNING *
    `, ['TEST_DIAG', 'Cliente Diagnóstico', '0999123456']);
    
    const clienteId = clienteTest.rows[0].id;
    console.log(`✅ Cliente creado: ID ${clienteId}`);

    // 2. Obtener producto
    console.log('\n📦 Obteniendo producto...');
    const productos = await pool.query('SELECT * FROM articulos LIMIT 1');
    const producto = productos.rows[0];
    console.log(`✅ Producto: ${producto.nombre} (ID: ${producto.id})`);

    // 3. Simular venta paso a paso
    console.log('\n💳 Simulando venta...');
    
    // Obtener un usuario válido para la prueba
    console.log('👤 Obteniendo usuario para la prueba...');
    const usuarios = await pool.query('SELECT id FROM usuarios LIMIT 1');
    const usuarioId = usuarios.rows.length > 0 ? usuarios.rows[0].id : 1;
    console.log(`✅ Usuario seleccionado: ID ${usuarioId}`);
    
    // Paso 1: Crear venta
    const venta = await pool.query(`
      INSERT INTO ventas (sucursal_id, usuario_id, cliente_id, fecha, total, numero_factura, forma_pago)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, [1, usuarioId, clienteId, new Date(), producto.precio_venta, `TEST-${Date.now()}`, 'efectivo']);
    
    const ventaId = venta.rows[0].id;
    console.log(`✅ Venta creada: ID ${ventaId}`);

    // Paso 2: Crear detalle
    const detalle = await pool.query(`
      INSERT INTO ventas_detalle (venta_id, producto_id, cantidad, precio_unitario, subtotal)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `, [ventaId, producto.id, 1, producto.precio_venta, producto.precio_venta]);
    
    console.log(`✅ Detalle creado: ID ${detalle.rows[0].id}`);

    // Paso 3: Actualizar fidelización
    console.log('\n🎯 Actualizando fidelización...');
    
    // Verificar si hay campañas activas
    const campanias = await pool.query(`
      SELECT id FROM fidelizacion_campanias WHERE activa = true LIMIT 1
    `);
    
    if (campanias.rows.length > 0) {
      const campaniaId = campanias.rows[0].id;
      
      // Calcular puntos
      const puntosBase = Math.floor(producto.precio_venta / 1000);
      const bonificacion = Math.floor(puntosBase * 0.2); // 20% efectivo
      const puntosTotales = puntosBase + bonificacion;
      
      console.log(`💰 Puntos calculados: ${puntosBase} base + ${bonificacion} bonificación = ${puntosTotales} total`);
      
      // Actualizar fidelización
      await pool.query(`
        INSERT INTO fidelizacion_clientes (cliente_id, campania_id, puntos_acumulados, ultima_actualizacion)
        VALUES ($1, $2, $3, NOW())
        ON CONFLICT (cliente_id, campania_id) 
        DO UPDATE SET 
          puntos_acumulados = fidelizacion_clientes.puntos_acumulados + $3,
          ultima_actualizacion = NOW()
      `, [clienteId, campaniaId, puntosTotales]);
      
      console.log(`✅ Fidelización actualizada`);
    } else {
      console.log('⚠️ No hay campañas activas para fidelización');
    }

    // 4. Verificar resultado final
    console.log('\n📊 Verificando resultado...');
    
    const ventaFinal = await pool.query(`
      SELECT 
        v.*,
        c.nombre as cliente_nombre,
        COUNT(vd.id) as total_detalles,
        SUM(vd.subtotal) as total_calculado
      FROM ventas v
      LEFT JOIN clientes c ON v.cliente_id = c.id
      LEFT JOIN ventas_detalle vd ON v.id = vd.venta_id
      WHERE v.id = $1
      GROUP BY v.id, c.nombre
    `, [ventaId]);
    
    if (ventaFinal.rows.length > 0) {
      const ventaData = ventaFinal.rows[0];
      console.log(`✅ Venta verificada:`);
      console.log(`   - ID: ${ventaData.id}`);
      console.log(`   - Cliente: ${ventaData.cliente_nombre}`);
      console.log(`   - Total: $${ventaData.total}`);
      console.log(`   - Método: ${ventaData.forma_pago}`);
      console.log(`   - Detalles: ${ventaData.total_detalles}`);
      console.log(`   - Total calculado: $${ventaData.total_calculado}`);
    }

    // 5. Verificar fidelización final
    const fidelizacionFinal = await pool.query(`
      SELECT fc.*, c.nombre as cliente_nombre
      FROM fidelizacion_clientes fc
      LEFT JOIN clientes c ON fc.cliente_id = c.id
      WHERE fc.cliente_id = $1
    `, [clienteId]);
    
    if (fidelizacionFinal.rows.length > 0) {
      console.log(`✅ Fidelización verificada:`);
      fidelizacionFinal.rows.forEach(fc => {
        console.log(`   - Cliente: ${fc.cliente_nombre}`);
        console.log(`   - Puntos: ${fc.puntos_acumulados}`);
        console.log(`   - Campaña: ${fc.campania_id}`);
      });
    }

    console.log('\n🎉 Prueba completada exitosamente!');
    console.log('✅ No se detectaron errores en el flujo');

  } catch (error) {
    console.error('❌ Error en la prueba:', error);
    console.error('Stack trace:', error.stack);
  } finally {
    await pool.end();
  }
}

testVentaCompleta();