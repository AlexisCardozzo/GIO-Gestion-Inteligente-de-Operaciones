const pool = require('./config/database');

async function crearCampaniasFormaPagoSimple() {
  try {
    console.log('🎯 Creando campañas de fidelización por forma de pago...\n');

    // 1. Campaña para incentivar pagos en efectivo
    const campaniaEfectivoQuery = `
      INSERT INTO fidelizacion_campanias (nombre, descripcion, fecha_inicio, fecha_fin, activa, tipo_campania)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id
    `;
    
    const campaniaEfectivoResult = await pool.query(campaniaEfectivoQuery, [
      'Pago Efectivo Premium',
      '¡Gana puntos extra pagando en efectivo! Obtén 20% más de puntos en todas tus compras.',
      new Date(),
      new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 año
      true,
      'forma_pago_efectivo'
    ]);
    
    const campaniaEfectivoId = campaniaEfectivoResult.rows[0].id;
    console.log('✅ Campaña "Pago Efectivo Premium" creada: ID', campaniaEfectivoId);

    // 2. Campaña para incentivar pagos con tarjeta
    const campaniaTarjetaQuery = `
      INSERT INTO fidelizacion_campanias (nombre, descripcion, fecha_inicio, fecha_fin, activa, tipo_campania)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id
    `;
    
    const campaniaTarjetaResult = await pool.query(campaniaTarjetaQuery, [
      'Pago Digital Plus',
      '¡Incentiva la digitalización! Gana 15% más de puntos pagando con tarjeta.',
      new Date(),
      new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 año
      true,
      'forma_pago_tarjeta'
    ]);
    
    const campaniaTarjetaId = campaniaTarjetaResult.rows[0].id;
    console.log('✅ Campaña "Pago Digital Plus" creada: ID', campaniaTarjetaId);

    // 3. Campaña para incentivar pagos QR
    const campaniaQRQuery = `
      INSERT INTO fidelizacion_campanias (nombre, descripcion, fecha_inicio, fecha_fin, activa, tipo_campania)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id
    `;
    
    const campaniaQRResult = await pool.query(campaniaQRQuery, [
      'Pago Móvil VIP',
      '¡La forma más moderna de pagar! Gana 25% más de puntos con pagos QR.',
      new Date(),
      new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 año
      true,
      'forma_pago_qr'
    ]);
    
    const campaniaQRId = campaniaQRResult.rows[0].id;
    console.log('✅ Campaña "Pago Móvil VIP" creada: ID', campaniaQRId);

    // 4. Crear requisitos para cada campaña
    const requisitos = [
      { campania_id: campaniaEfectivoId, tipo: 'ventas_efectivo', valor: 1, descripcion: 'Realizar al menos 1 venta pagando en efectivo' },
      { campania_id: campaniaTarjetaId, tipo: 'ventas_tarjeta', valor: 1, descripcion: 'Realizar al menos 1 venta pagando con tarjeta' },
      { campania_id: campaniaQRId, tipo: 'ventas_qr', valor: 1, descripcion: 'Realizar al menos 1 venta pagando con QR' }
    ];

    for (const requisito of requisitos) {
      const requisitoQuery = `
        INSERT INTO fidelizacion_requisitos (campania_id, tipo, valor, descripcion)
        VALUES ($1, $2, $3, $4)
      `;
      
      await pool.query(requisitoQuery, [
        requisito.campania_id,
        requisito.tipo,
        requisito.valor,
        requisito.descripcion
      ]);
      
      console.log(`✅ Requisito "${requisito.descripcion}" creado`);
    }

    // 5. Crear beneficios para cada campaña
    const beneficios = [
      { campania_id: campaniaEfectivoId, tipo: 'descuento', valor: 10, descripcion: '10% de descuento en próxima compra con efectivo' },
      { campania_id: campaniaTarjetaId, tipo: 'descuento', valor: 8, descripcion: '8% de descuento en próxima compra con tarjeta' },
      { campania_id: campaniaQRId, tipo: 'descuento', valor: 12, descripcion: '12% de descuento en próxima compra con QR' }
    ];

    for (const beneficio of beneficios) {
      const beneficioQuery = `
        INSERT INTO fidelizacion_beneficios (campania_id, tipo, valor, descripcion)
        VALUES ($1, $2, $3, $4)
      `;
      
      await pool.query(beneficioQuery, [
        beneficio.campania_id,
        beneficio.tipo,
        beneficio.valor,
        beneficio.descripcion
      ]);
      
      console.log(`✅ Beneficio "${beneficio.descripcion}" creado`);
    }

    console.log('\n🎉 Campañas de fidelización por forma de pago creadas exitosamente!');
    console.log('\n📋 Resumen de campañas:');
    console.log('   - Pago Efectivo Premium: +20% puntos');
    console.log('   - Pago Digital Plus: +15% puntos');
    console.log('   - Pago Móvil VIP: +25% puntos');
    console.log('\n💡 Estas campañas se activan automáticamente según la forma de pago utilizada');

  } catch (error) {
    console.error('❌ Error creando campañas:', error);
  } finally {
    await pool.end();
  }
}

crearCampaniasFormaPagoSimple(); 