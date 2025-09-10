const pool = require('./config/database');

async function activarProductos() {
  try {
    console.log('🔧 Activando productos...\n');

    // 1. Verificar productos inactivos
    console.log('📊 Productos inactivos:');
    const productosInactivos = await pool.query(`
      SELECT id, nombre, activo, stock_minimo, precio_venta, precio_compra
      FROM articulos
      WHERE activo = false
      ORDER BY id
    `);

    if (productosInactivos.rows.length === 0) {
      console.log('✅ Todos los productos están activos');
      return;
    }

    productosInactivos.rows.forEach(producto => {
      console.log(`  - ${producto.nombre} (ID: ${producto.id}):`);
      console.log(`    Stock: ${producto.stock_minimo}, Precio: $${producto.precio_venta}`);
    });

    // 2. Activar productos y corregir stock
    console.log('\n🔧 Activando productos...');
    for (const producto of productosInactivos.rows) {
      // Corregir stock negativo
      let stockCorregido = producto.stock_minimo;
      if (stockCorregido < 0) {
        stockCorregido = 10; // Stock mínimo razonable
        console.log(`  - Corrigiendo stock de ${producto.nombre}: ${producto.stock_minimo} → ${stockCorregido}`);
      }

      // Activar producto
      await pool.query(
        'UPDATE articulos SET activo = true, stock_minimo = $1 WHERE id = $2',
        [stockCorregido, producto.id]
      );

      console.log(`  ✅ ${producto.nombre} activado con stock ${stockCorregido}`);
    }

    // 3. Verificar resultado
    console.log('\n📊 Productos activos después de la corrección:');
    const productosActivos = await pool.query(`
      SELECT id, nombre, activo, stock_minimo, precio_venta
      FROM articulos
      WHERE activo = true
      ORDER BY id
    `);

    productosActivos.rows.forEach(producto => {
      console.log(`  - ${producto.nombre} (ID: ${producto.id}):`);
      console.log(`    Stock: ${producto.stock_minimo}, Precio: $${producto.precio_venta}`);
    });

    // 4. Crear movimientos de stock inicial para productos activados
    console.log('\n📦 Creando movimientos de stock inicial...');
    for (const producto of productosActivos.rows) {
      if (producto.stock_minimo > 0) {
        // Verificar si ya tiene movimientos
        const movimientos = await pool.query(
          'SELECT COUNT(*) as total FROM movimientos_stock WHERE articulo_id = $1',
          [producto.id]
        );

        if (movimientos.rows[0].total == 0) {
          await pool.query(
            'INSERT INTO movimientos_stock (articulo_id, tipo_movimiento, cantidad, stock_antes, stock_despues, referencia, fecha_hora) VALUES ($1, $2, $3, $4, $5, $6, NOW())',
            [producto.id, 'entrada', producto.stock_minimo, 0, producto.stock_minimo, 'Stock inicial (activado)']
          );
          console.log(`  ✅ Movimiento inicial creado para ${producto.nombre}`);
        }
      }
    }

    // 5. Resumen final
    console.log('\n📈 Resumen final:');
    const totalProductos = await pool.query('SELECT COUNT(*) as total FROM articulos WHERE activo = true');
    const totalMovimientos = await pool.query('SELECT COUNT(*) as total FROM movimientos_stock');
    
    console.log(`  - Productos activos: ${totalProductos.rows[0].total}`);
    console.log(`  - Total movimientos: ${totalMovimientos.rows[0].total}`);

    console.log('\n🎉 Activación de productos completada!');
    console.log('💡 Ahora puedes crear productos y realizar ventas');

  } catch (error) {
    console.error('❌ Error durante la activación:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar la activación
activarProductos();
