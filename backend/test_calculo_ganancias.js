require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function testCalculoGanancias() {
  try {
    console.log('💰 Probando cálculo de ganancias...\n');
    
    // 1. Verificar productos disponibles
    console.log('📦 Productos disponibles:');
    const productosResult = await pool.query(`
      SELECT id, nombre, precio_compra, precio_venta, iva
      FROM articulos 
      WHERE activo = true
      LIMIT 3
    `);
    
    productosResult.rows.forEach((producto, index) => {
      console.log(`  ${index + 1}. ${producto.nombre}`);
      console.log(`     Precio compra: Gs ${producto.precio_compra}`);
      console.log(`     Precio venta: Gs ${producto.precio_venta}`);
      console.log(`     IVA: ${producto.iva}%`);
      const gananciaUnitaria = producto.precio_venta - producto.precio_compra;
      const gananciaBruta = gananciaUnitaria;
      const gananciaNeta = gananciaBruta - (gananciaBruta * producto.iva / 100);
      console.log(`     Ganancia unitaria bruta: Gs ${gananciaBruta}`);
      console.log(`     Ganancia unitaria neta: Gs ${gananciaNeta.toFixed(2)}`);
      console.log('');
    });
    
    // 2. Verificar ventas recientes con detalles
    console.log('📊 Ventas recientes con cálculos:');
    const ventasResult = await pool.query(`
      SELECT 
        v.id,
        v.total,
        dv.producto_id,
        dv.cantidad,
        dv.precio_unitario,
        dv.subtotal,
        a.nombre as producto,
        a.precio_compra,
        a.iva
      FROM ventas v
      LEFT JOIN detalle_ventas dv ON v.id = dv.venta_id
      LEFT JOIN articulos a ON dv.producto_id = a.id
      ORDER BY v.fecha DESC
      LIMIT 5
    `);
    
    let ventaActual = null;
    let totalGananciaBruta = 0;
    let totalGananciaNeta = 0;
    
    ventasResult.rows.forEach((row, index) => {
      if (row.producto_id) {
        if (ventaActual !== row.id) {
          if (ventaActual !== null) {
            console.log(`     Total ganancia bruta: Gs ${totalGananciaBruta.toFixed(2)}`);
            console.log(`     Total ganancia neta: Gs ${totalGananciaNeta.toFixed(2)}`);
            console.log('');
          }
          console.log(`  Venta ${row.id} - Total: Gs ${row.total}`);
          ventaActual = row.id;
          totalGananciaBruta = 0;
          totalGananciaNeta = 0;
        }
        
        const gananciaUnitaria = row.precio_unitario - row.precio_compra;
        const gananciaBruta = gananciaUnitaria * row.cantidad;
        const gananciaNeta = gananciaBruta - (gananciaBruta * row.iva / 100);
        
        totalGananciaBruta += gananciaBruta;
        totalGananciaNeta += gananciaNeta;
        
        console.log(`    - ${row.producto}: ${row.cantidad} x Gs ${row.precio_unitario} = Gs ${row.subtotal}`);
        console.log(`      Ganancia bruta: Gs ${gananciaBruta.toFixed(2)}`);
        console.log(`      Ganancia neta: Gs ${gananciaNeta.toFixed(2)}`);
      }
    });
    
    if (ventaActual !== null) {
      console.log(`     Total ganancia bruta: Gs ${totalGananciaBruta.toFixed(2)}`);
      console.log(`     Total ganancia neta: Gs ${totalGananciaNeta.toFixed(2)}`);
    }
    
    // 3. Simular cálculo de ganancias para una venta
    console.log('\n🧮 Simulando cálculo de ganancias:');
    if (productosResult.rows.length > 0) {
      const producto = productosResult.rows[0];
      const cantidad = 2;
      const precioUnitario = producto.precio_venta;
      const subtotal = precioUnitario * cantidad;
      
      console.log(`  Producto: ${producto.nombre}`);
      console.log(`  Cantidad: ${cantidad}`);
      console.log(`  Precio unitario: Gs ${precioUnitario}`);
      console.log(`  Subtotal: Gs ${subtotal}`);
      
      const gananciaUnitaria = precioUnitario - producto.precio_compra;
      const gananciaBruta = gananciaUnitaria * cantidad;
      const gananciaNeta = gananciaBruta - (gananciaBruta * producto.iva / 100);
      
      console.log(`  Ganancia unitaria: Gs ${gananciaUnitaria}`);
      console.log(`  Ganancia bruta total: Gs ${gananciaBruta.toFixed(2)}`);
      console.log(`  Ganancia neta total: Gs ${gananciaNeta.toFixed(2)}`);
    }
    
    console.log('\n✅ Prueba de cálculo completada');
    
  } catch (error) {
    console.error('❌ Error en prueba de cálculo:', error);
  } finally {
    await pool.end();
  }
}

testCalculoGanancias(); 