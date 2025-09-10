const pool = require('./config/database');

async function verificarStockUsuario() {
  try {
    console.log('🔍 Verificando stock por usuario...');
    
    // 1. Obtener todos los usuarios con sus productos
    const usuariosResult = await pool.query(`
      SELECT u.id, u.nombre, u.email, COUNT(a.id) as total_productos
      FROM usuarios u
      LEFT JOIN articulos a ON u.id = a.usuario_id
      GROUP BY u.id, u.nombre, u.email
      ORDER BY u.id
    `);
    
    console.log('\n📊 Usuarios y sus productos:');
    usuariosResult.rows.forEach(usuario => {
      console.log(`  - Usuario ID ${usuario.id}: ${usuario.nombre} (${usuario.email}) - ${usuario.total_productos} productos`);
    });
    
    // 2. Verificar stock por usuario
    console.log('\n📊 Detalle de stock por usuario:');
    for (const usuario of usuariosResult.rows) {
      if (usuario.total_productos > 0) {
        const stockResult = await pool.query(`
          SELECT 
            a.id, 
            a.nombre, 
            a.codigo, 
            a.stock_minimo,
            COALESCE(SUM(
              CASE 
                WHEN ms.tipo_movimiento = 'entrada' THEN ms.cantidad 
                WHEN ms.tipo_movimiento = 'salida' THEN -ms.cantidad 
                ELSE 0 
              END
            ), 0) as stock_calculado
          FROM articulos a
          LEFT JOIN movimientos_stock ms ON a.id = ms.articulo_id
          WHERE a.usuario_id = $1
          GROUP BY a.id, a.nombre, a.codigo, a.stock_minimo
        `, [usuario.id]);
        
        console.log(`\n  Usuario ID ${usuario.id}: ${usuario.nombre}`);
        console.log(`  Total productos: ${stockResult.rows.length}`);
        
        let totalStockBD = 0;
        let totalStockCalculado = 0;
        
        stockResult.rows.forEach(producto => {
          totalStockBD += parseInt(producto.stock_minimo || 0);
          totalStockCalculado += parseInt(producto.stock_calculado || 0);
          
          console.log(`    - ${producto.nombre} (ID: ${producto.id}): Stock BD: ${producto.stock_minimo}, Stock calculado: ${producto.stock_calculado}`);
        });
        
        console.log(`  Total stock en BD: ${totalStockBD}`);
        console.log(`  Total stock calculado: ${totalStockCalculado}`);
        
        // 3. Verificar movimientos de stock
        const movimientosResult = await pool.query(`
          SELECT COUNT(*) as total_movimientos
          FROM movimientos_stock ms
          JOIN articulos a ON ms.articulo_id = a.id
          WHERE a.usuario_id = $1
        `, [usuario.id]);
        
        console.log(`  Total movimientos de stock: ${movimientosResult.rows[0].total_movimientos}`);
      }
    }
    
    // 4. Verificar si hay inconsistencias
    console.log('\n🔍 Verificando inconsistencias de stock...');
    const inconsistenciasResult = await pool.query(`
      SELECT 
        a.id, 
        a.nombre, 
        a.codigo, 
        a.usuario_id,
        a.stock_minimo as stock_bd,
        COALESCE(SUM(
          CASE 
            WHEN ms.tipo_movimiento = 'entrada' THEN ms.cantidad 
            WHEN ms.tipo_movimiento = 'salida' THEN -ms.cantidad 
            ELSE 0 
          END
        ), 0) as stock_calculado
      FROM articulos a
      LEFT JOIN movimientos_stock ms ON a.id = ms.articulo_id
      GROUP BY a.id, a.nombre, a.codigo, a.usuario_id, a.stock_minimo
      HAVING ABS(a.stock_minimo - COALESCE(SUM(
        CASE 
          WHEN ms.tipo_movimiento = 'entrada' THEN ms.cantidad 
          WHEN ms.tipo_movimiento = 'salida' THEN -ms.cantidad 
          ELSE 0 
        END
      ), 0)) > 0
    `);
    
    if (inconsistenciasResult.rows.length === 0) {
      console.log('✅ No hay inconsistencias de stock');
    } else {
      console.log(`❌ Se encontraron ${inconsistenciasResult.rows.length} inconsistencias de stock:`);
      inconsistenciasResult.rows.forEach(item => {
        console.log(`  - ${item.nombre} (ID: ${item.id}, Usuario ID: ${item.usuario_id}): Stock BD: ${item.stock_bd}, Stock calculado: ${item.stock_calculado}`);
      });
    }
    
    console.log('\n💡 Recomendaciones:');
    console.log('  1. Asegúrate de estar autenticado con un usuario que tenga productos registrados');
    console.log('  2. Verifica que los productos tengan stock_minimo > 0');
    console.log('  3. Verifica que haya movimientos de stock registrados para los productos');
    console.log('  4. Si hay inconsistencias, ejecuta el script corregir_stock_final.js para corregirlas');
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

verificarStockUsuario();