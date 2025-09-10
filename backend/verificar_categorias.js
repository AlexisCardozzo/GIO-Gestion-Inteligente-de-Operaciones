const pool = require('./config/database');

async function verificarCategorias() {
  try {
    console.log('🔍 Verificando categorías en la base de datos...\n');

    // 1. Verificar si existe la tabla categorias
    console.log('📋 Verificando tabla categorias...');
    const tablaExiste = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'categorias'
      );
    `);
    
    if (tablaExiste.rows[0].exists) {
      console.log('  ✅ Tabla categorias existe');
      
      // 2. Verificar categorías existentes
      const categorias = await pool.query('SELECT * FROM categorias ORDER BY id');
      console.log(`  - Categorías encontradas: ${categorias.rows.length}`);
      
      if (categorias.rows.length > 0) {
        categorias.rows.forEach(cat => {
          console.log(`    - ID ${cat.id}: ${cat.nombre || 'Sin nombre'}`);
        });
      } else {
        console.log('    - No hay categorías registradas');
      }
    } else {
      console.log('  ❌ Tabla categorias no existe');
    }

    // 3. Verificar estructura de la tabla articulos
    console.log('\n📋 Verificando estructura de tabla articulos...');
    const estructura = await pool.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'articulos' AND column_name = 'categoria_id'
      ORDER BY ordinal_position
    `);
    
    if (estructura.rows.length > 0) {
      const col = estructura.rows[0];
      console.log(`  - categoria_id: ${col.data_type} (nullable: ${col.is_nullable}, default: ${col.column_default})`);
    } else {
      console.log('  - No existe columna categoria_id');
    }

    // 4. Verificar restricciones de clave foránea
    console.log('\n📋 Verificando restricciones de clave foránea...');
    const restricciones = await pool.query(`
      SELECT 
        tc.constraint_name,
        tc.table_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
      WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND tc.table_name = 'articulos'
        AND kcu.column_name = 'categoria_id'
    `);
    
    if (restricciones.rows.length > 0) {
      restricciones.rows.forEach(rest => {
        console.log(`  - ${rest.constraint_name}: ${rest.column_name} → ${rest.foreign_table_name}.${rest.foreign_column_name}`);
      });
    } else {
      console.log('  - No hay restricciones de clave foránea para categoria_id');
    }

    // 5. Verificar productos existentes
    console.log('\n📋 Verificando productos existentes...');
    const productos = await pool.query('SELECT id, nombre, categoria_id FROM articulos ORDER BY id LIMIT 5');
    console.log(`  - Productos encontrados: ${productos.rows.length}`);
    
    productos.rows.forEach(prod => {
      console.log(`    - ID ${prod.id}: ${prod.nombre} (categoria_id: ${prod.categoria_id || 'NULL'})`);
    });

    console.log('\n🎉 Verificación completada!');

  } catch (error) {
    console.error('❌ Error durante la verificación:', error);
  } finally {
    await pool.end();
  }
}

verificarCategorias();
