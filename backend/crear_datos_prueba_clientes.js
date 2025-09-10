const pool = require('./config/database');

async function crearDatosPrueba() {
  try {
    console.log('🔄 Creando datos de prueba para clientes en riesgo...\n');

    // 1. Crear clientes de prueba
    console.log('1️⃣ Creando clientes de prueba...');
    const clientesResult = await pool.query(`
      INSERT INTO clientes (nombre, identificador, telefono, activo) VALUES
        ('Juan Pérez', 'CLI001', '1234567890', true),
        ('María García', 'CLI002', '0987654321', true),
        ('Carlos López', 'CLI003', '1122334455', true),
        ('Ana Martínez', 'CLI004', '5566778899', true),
        ('Luis Rodríguez', 'CLI005', '9988776655', true)
      ON CONFLICT (identificador) DO NOTHING
      RETURNING id, nombre
    `);
    
    console.log(`✅ ${clientesResult.rowCount} clientes creados/verificados`);

    // 2. Crear ventas de prueba con diferentes fechas
    console.log('\n2️⃣ Creando ventas de prueba...');
    
    const fechaActual = new Date();
    const ventas = [
      // Cliente 1: Última compra hace 2 días (no en riesgo)
      { cliente_id: 1, fecha: new Date(fechaActual.getTime() - 2 * 24 * 60 * 60 * 1000), total: 150.00 },
      { cliente_id: 1, fecha: new Date(fechaActual.getTime() - 5 * 24 * 60 * 60 * 1000), total: 200.00 },
      
      // Cliente 2: Última compra hace 5 días (riesgo bajo)
      { cliente_id: 2, fecha: new Date(fechaActual.getTime() - 5 * 24 * 60 * 60 * 1000), total: 300.00 },
      { cliente_id: 2, fecha: new Date(fechaActual.getTime() - 10 * 24 * 60 * 60 * 1000), total: 250.00 },
      
      // Cliente 3: Última compra hace 8 días (riesgo medio)
      { cliente_id: 3, fecha: new Date(fechaActual.getTime() - 8 * 24 * 60 * 60 * 1000), total: 180.00 },
      { cliente_id: 3, fecha: new Date(fechaActual.getTime() - 15 * 24 * 60 * 60 * 1000), total: 120.00 },
      
      // Cliente 4: Última compra hace 12 días (riesgo alto)
      { cliente_id: 4, fecha: new Date(fechaActual.getTime() - 12 * 24 * 60 * 60 * 1000), total: 400.00 },
      { cliente_id: 4, fecha: new Date(fechaActual.getTime() - 20 * 24 * 60 * 60 * 1000), total: 350.00 },
      
      // Cliente 5: Última compra hace 15 días (riesgo alto)
      { cliente_id: 5, fecha: new Date(fechaActual.getTime() - 15 * 24 * 60 * 60 * 1000), total: 280.00 },
      { cliente_id: 5, fecha: new Date(fechaActual.getTime() - 25 * 24 * 60 * 60 * 1000), total: 220.00 }
    ];

    for (const venta of ventas) {
      await pool.query(`
        INSERT INTO ventas (cliente_id, fecha, total, numero_factura) VALUES ($1, $2, $3, $4)
        ON CONFLICT DO NOTHING
      `, [venta.cliente_id, venta.fecha, venta.total, `FAC-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`]);
    }
    
    console.log(`✅ ${ventas.length} ventas de prueba creadas`);

    // 3. Verificar datos creados
    console.log('\n3️⃣ Verificando datos creados...');
    
    const clientesCount = await pool.query('SELECT COUNT(*) FROM clientes WHERE activo = true');
    const ventasCount = await pool.query('SELECT COUNT(*) FROM ventas WHERE cliente_id IS NOT NULL');
    
    console.log(`📊 Total clientes activos: ${clientesCount.rows[0].count}`);
    console.log(`📊 Total ventas con cliente: ${ventasCount.rows[0].count}`);

    // 4. Mostrar resumen de ventas por cliente
    const resumenVentas = await pool.query(`
      SELECT 
        c.nombre,
        COUNT(v.id) as total_ventas,
        MAX(v.fecha) as ultima_compra,
        EXTRACT(DAY FROM (NOW() - MAX(v.fecha))) as dias_sin_comprar
      FROM clientes c
      LEFT JOIN ventas v ON c.id = v.cliente_id
      WHERE c.activo = true
      GROUP BY c.id, c.nombre
      ORDER BY dias_sin_comprar DESC
    `);

    console.log('\n📋 Resumen de ventas por cliente:');
    resumenVentas.rows.forEach(cliente => {
      console.log(`  - ${cliente.nombre}: ${cliente.total_ventas} ventas, última compra hace ${cliente.dias_sin_comprar || 'Nunca'} días`);
    });

    console.log('\n🎉 Datos de prueba creados exitosamente!');
    console.log('💡 Ahora puedes probar la funcionalidad de clientes en riesgo');

  } catch (error) {
    console.error('❌ Error creando datos de prueba:', error);
  } finally {
    await pool.end();
  }
}

crearDatosPrueba(); 