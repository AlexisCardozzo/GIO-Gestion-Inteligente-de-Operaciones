const pool = require('./config/database');

async function checkProducts() {
  try {
    console.log('Verificando productos en la base de datos...\n');
    
    // Obtener todos los productos
    const result = await pool.query('SELECT id, nombre, codigo, stock_minimo, precio_venta FROM articulos ORDER BY nombre');
    
    console.log(`Total de productos encontrados: ${result.rows.length}\n`);
    
    if (result.rows.length > 0) {
      result.rows.forEach((producto, index) => {
        console.log(`${index + 1}. ID: ${producto.id} | Nombre: ${producto.nombre} | Código: ${producto.codigo} | Stock: ${producto.stock_minimo} | Precio: $${producto.precio_venta}`);
      });
    } else {
      console.log('No hay productos en la base de datos.');
    }
    
    // Probar búsqueda
    console.log('\n=== Probando búsquedas ===');
    
    const searchTerms = ['test', '123', 'producto', 'a'];
    
    for (const term of searchTerms) {
      const searchResult = await pool.query(
        'SELECT id, nombre, codigo, stock_minimo FROM articulos WHERE nombre ILIKE $1 OR codigo ILIKE $1',
        [`%${term}%`]
      );
      console.log(`Búsqueda "${term}": ${searchResult.rows.length} productos encontrados`);
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkProducts(); 