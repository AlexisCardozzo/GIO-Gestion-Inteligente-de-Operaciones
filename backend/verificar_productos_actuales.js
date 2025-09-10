const pool = require('./config/database');

async function verificarProductosActuales() {
  try {
    console.log('🔍 Verificando productos actuales...\n');

    // Verificar todos los productos
    const productos = await pool.query(`
      SELECT id, nombre, codigo, activo, stock_minimo, precio_venta
      FROM articulos
      ORDER BY id
    `);

    console.log('📊 Productos en la base de datos:');
    if (productos.rows.length === 0) {
      console.log('  - No hay productos registrados');
    } else {
      productos.rows.forEach(producto => {
        console.log(`  - ID: ${producto.id} | Nombre: ${producto.nombre} | Código: ${producto.codigo || 'Sin código'} | Activo: ${producto.activo} | Stock: ${producto.stock_minimo} | Precio: $${producto.precio_venta}`);
      });
    }

    // Verificar restricciones de la tabla
    console.log('\n📋 Restricciones de la tabla articulos:');
    const restricciones = await pool.query(`
      SELECT 
        tc.constraint_name,
        tc.constraint_type,
        kcu.column_name
      FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
      WHERE tc.table_name = 'articulos'
      ORDER BY tc.constraint_name
    `);

    restricciones.rows.forEach(restriccion => {
      console.log(`  - ${restriccion.constraint_name}: ${restriccion.constraint_type} en ${restriccion.column_name}`);
    });

    console.log('\n💡 Información para solucionar el problema:');
    console.log('  - El error indica que ya existe un producto con código "01"');
    console.log('  - La restricción articulos_codigo_key impide códigos duplicados');
    console.log('  - Necesitas usar un código único o eliminar el producto existente');

  } catch (error) {
    console.error('❌ Error durante la verificación:', error);
  } finally {
    await pool.end();
  }
}

// Ejecutar la verificación
verificarProductosActuales();
