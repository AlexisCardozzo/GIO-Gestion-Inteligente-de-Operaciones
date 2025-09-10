const pool = require('./config/database');

async function agregarMovimientosStock() {
  try {
    console.log('🔧 Agregando movimientos de stock iniciales...');
    
    // 1. Obtener productos sin movimientos de stock
    console.log('\n🔍 Buscando productos sin movimientos de stock...');
    const sinMovimientosResult = await pool.query(`
      SELECT a.id, a.nombre, a.codigo, a.usuario_id, a.stock_minimo
      FROM articulos a
      LEFT JOIN movimientos_stock ms ON a.id = ms.articulo_id
      WHERE ms.id IS NULL AND a.stock_minimo > 0
    `);
    
    if (sinMovimientosResult.rows.length === 0) {
      console.log('✅ Todos los productos con stock tienen movimientos registrados');
    } else {
      console.log(`❌ Se encontraron ${sinMovimientosResult.rows.length} productos con stock pero sin movimientos:`);
      
      // 2. Crear movimientos de entrada para productos sin movimientos
      console.log('\n🔧 Creando movimientos de entrada para productos sin movimientos...');
      
      for (const producto of sinMovimientosResult.rows) {
        console.log(`  - Creando movimiento para ${producto.nombre} (ID: ${producto.id}): Stock: ${producto.stock_minimo}`);
        
        // Crear un movimiento de entrada para el stock actual
        await pool.query(
          'INSERT INTO movimientos_stock (articulo_id, tipo_movimiento, cantidad, stock_antes, stock_despues, referencia, fecha_hora) VALUES ($1, $2, $3, $4, $5, $6, NOW())',
          [producto.id, 'entrada', producto.stock_minimo, 0, producto.stock_minimo, 'Stock inicial']
        );
      }
      
      console.log('\n✅ Movimientos creados correctamente');
    }
    
    // 3. Verificar productos con stock cero pero que deberían tener
    console.log('\n🔍 Verificando productos con stock cero...');
    const stockCeroResult = await pool.query(`
      SELECT a.id, a.nombre, a.codigo, a.usuario_id, a.stock_minimo
      FROM articulos a
      WHERE a.stock_minimo = 0 AND a.activo = true
    `);
    
    if (stockCeroResult.rows.length === 0) {
      console.log('✅ No hay productos con stock cero');
    } else {
      console.log(`ℹ️ Se encontraron ${stockCeroResult.rows.length} productos con stock cero:`);
      
      for (const producto of stockCeroResult.rows) {
        console.log(`  - ${producto.nombre} (ID: ${producto.id})`);
      }
      
      // Preguntar si se desea agregar stock a estos productos
      console.log('\n💡 Para agregar stock a estos productos, utiliza la función "registrarMovimiento" en el controlador de stock');
    }
    
    // 4. Verificar usuarios sin productos
    console.log('\n🔍 Verificando usuarios sin productos...');
    const usuariosSinProductosResult = await pool.query(`
      SELECT u.id, u.nombre, u.email
      FROM usuarios u
      LEFT JOIN articulos a ON u.id = a.usuario_id
      GROUP BY u.id, u.nombre, u.email
      HAVING COUNT(a.id) = 0
    `);
    
    if (usuariosSinProductosResult.rows.length === 0) {
      console.log('✅ Todos los usuarios tienen productos registrados');
    } else {
      console.log(`ℹ️ Se encontraron ${usuariosSinProductosResult.rows.length} usuarios sin productos:`);
      
      for (const usuario of usuariosSinProductosResult.rows) {
        console.log(`  - ${usuario.nombre} (${usuario.email})`);
      }
      
      console.log('\n💡 Para que estos usuarios vean datos en el resumen de stock, deben agregar productos');
    }
    
    console.log('\n🎉 Proceso completado con éxito');
    console.log('\n💡 Recomendaciones:');
    console.log('  1. Reinicia el servidor backend para aplicar los cambios');
    console.log('  2. Actualiza la pantalla de stock en el frontend');
    console.log('  3. Verifica que los resúmenes de stock muestren los valores correctos');
    console.log('  4. Para agregar stock a un producto, utiliza la función "Registrar movimiento" en la pantalla de stock');
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

agregarMovimientosStock();