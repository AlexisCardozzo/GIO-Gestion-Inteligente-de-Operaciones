require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testVentaSimple() {
  try {
    console.log('🧪 Probando registro de venta simple...\n');
    
    // 1. Verificar estado inicial
    console.log('📊 Estado inicial:');
    const ventasInicial = await pool.query('SELECT COUNT(*) as count FROM ventas');
    const detallesInicial = await pool.query('SELECT COUNT(*) as count FROM detalle_ventas');
    console.log(`  Ventas: ${ventasInicial.rows[0].count}`);
    console.log(`  Detalles: ${detallesInicial.rows[0].count}`);
    
    // 2. Crear una venta de prueba
    console.log('\n💰 Creando venta de prueba...');
    
    // Primero necesitamos un cliente y un artículo
    const clienteResult = await pool.query('SELECT id FROM clientes LIMIT 1');
    const articuloResult = await pool.query('SELECT id, precio_venta FROM articulos LIMIT 1');
    
    if (clienteResult.rows.length === 0 || articuloResult.rows.length === 0) {
      console.log('❌ Necesitas crear al menos un cliente y un artículo primero');
      return;
    }
    
    const cliente_id = clienteResult.rows[0].id;
    const articulo = articuloResult.rows[0];
    const cantidad = 2;
    const precio_unitario = parseFloat(articulo.precio_venta);
    const subtotal = precio_unitario * cantidad;
    
    // Obtener un usuario válido para la prueba
    console.log('👤 Obteniendo usuario para la prueba...');
    const usuarios = await pool.query('SELECT id FROM usuarios LIMIT 1');
    const usuarioId = usuarios.rows.length > 0 ? usuarios.rows[0].id : 1;
    console.log(`✅ Usuario seleccionado: ID ${usuarioId}`);
    
    // Simular el payload de una venta
    const ventaPayload = {
      sucursal_id: 1,
      usuario_id: usuarioId,
      cliente_id: cliente_id,
      total: subtotal,
      items: [
        {
          producto_id: articulo.id,
          cantidad: cantidad,
          precio_unitario: precio_unitario,
          subtotal: subtotal
        }
      ]
    };
    
    console.log('📝 Payload de venta:', JSON.stringify(ventaPayload, null, 2));
    
    // 3. Registrar la venta usando el controlador
    const VentaController = require('./controllers/ventaController');
    
    // Simular request/response
    const req = { body: ventaPayload };
    const res = {
      status: (code) => ({
        json: (data) => {
          console.log(`📤 Response (${code}):`, JSON.stringify(data, null, 2));
          return data;
        }
      }),
      json: (data) => {
        console.log('📤 Response:', JSON.stringify(data, null, 2));
        return data;
      }
    };
    
    await VentaController.crear(req, res);
    
    // 4. Verificar estado final
    console.log('\n📊 Estado final:');
    const ventasFinal = await pool.query('SELECT COUNT(*) as count FROM ventas');
    const detallesFinal = await pool.query('SELECT COUNT(*) as count FROM detalle_ventas');
    console.log(`  Ventas: ${ventasFinal.rows[0].count}`);
    console.log(`  Detalles: ${detallesFinal.rows[0].count}`);
    
    // 5. Verificar que solo se agregó 1 venta y 1 detalle
    const ventasAgregadas = parseInt(ventasFinal.rows[0].count) - parseInt(ventasInicial.rows[0].count);
    const detallesAgregados = parseInt(detallesFinal.rows[0].count) - parseInt(detallesInicial.rows[0].count);
    
    console.log('\n🎯 Resultado:');
    console.log(`  Ventas agregadas: ${ventasAgregadas}`);
    console.log(`  Detalles agregados: ${detallesAgregados}`);
    
    if (ventasAgregadas === 1 && detallesAgregados === 1) {
      console.log('✅ ¡Prueba exitosa! No hay duplicación.');
    } else {
      console.log('❌ ¡Hay duplicación! Se agregaron más registros de los esperados.');
    }
    
  } catch (error) {
    console.error('❌ Error en la prueba:', error);
  } finally {
    await pool.end();
  }
}

testVentaSimple();