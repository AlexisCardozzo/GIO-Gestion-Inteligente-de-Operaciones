const pool = require('./config/database');

async function agregarStockProductos() {
  try {
    console.log('🔧 Agregando stock a productos con stock cero...');
    
    // 1. Obtener productos con stock cero
    console.log('\n🔍 Buscando productos con stock cero...');
    const stockCeroResult = await pool.query(`
      SELECT a.id, a.nombre, a.codigo, a.usuario_id, a.stock_minimo
      FROM articulos a
      WHERE a.stock_minimo = 0 AND a.activo = true
    `);
    
    if (stockCeroResult.rows.length === 0) {
      console.log('✅ No hay productos con stock cero');
      return;
    }
    
    console.log(`ℹ️ Se encontraron ${stockCeroResult.rows.length} productos con stock cero:`);
    for (const producto of stockCeroResult.rows) {
      console.log(`  - ${producto.nombre} (ID: ${producto.id})`);
    }
    
    // 2. Agregar stock a los productos
    console.log('\n🔧 Agregando stock a los productos...');
    
    for (const producto of stockCeroResult.rows) {
      // Definir una cantidad de stock para agregar (10 unidades)
      const cantidadStock = 10;
      
      console.log(`  - Agregando ${cantidadStock} unidades a ${producto.nombre} (ID: ${producto.id})`);
      
      // Actualizar el stock_minimo en la tabla articulos
      await pool.query(
        'UPDATE articulos SET stock_minimo = $1 WHERE id = $2',
        [cantidadStock, producto.id]
      );
      
      // Registrar un movimiento de entrada
      await pool.query(
        'INSERT INTO movimientos_stock (articulo_id, tipo_movimiento, cantidad, stock_antes, stock_despues, referencia, fecha_hora) VALUES ($1, $2, $3, $4, $5, $6, NOW())',
        [producto.id, 'entrada', cantidadStock, 0, cantidadStock, 'Stock inicial']
      );
    }
    
    console.log('\n✅ Stock agregado correctamente');
    
    // 3. Verificar el resultado
    console.log('\n🔍 Verificando resultado...');
    const resultadoFinal = await pool.query(`
      SELECT a.id, a.nombre, a.codigo, a.stock_minimo,
      (SELECT COUNT(*) FROM movimientos_stock ms WHERE ms.articulo_id = a.id) as total_movimientos
      FROM articulos a
      WHERE a.id IN (${stockCeroResult.rows.map(p => p.id).join(',')})
    `);
    
    console.log('\n📊 Estado final de los productos:');
    for (const producto of resultadoFinal.rows) {
      console.log(`  - ${producto.nombre} (ID: ${producto.id}): Stock: ${producto.stock_minimo}, Movimientos: ${producto.total_movimientos}`);
    }
    
    console.log('\n🎉 Proceso completado con éxito');
    console.log('\n💡 Recomendaciones:');
    console.log('  1. Reinicia el servidor backend para aplicar los cambios');
    console.log('  2. Actualiza la pantalla de stock en el frontend');
    console.log('  3. Verifica que los resúmenes de stock muestren los valores correctos');
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

agregarStockProductos();