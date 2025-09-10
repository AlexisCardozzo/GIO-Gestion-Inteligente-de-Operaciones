const pool = require('./config/database');

async function migrarIdentificadorOpcional() {
  try {
    console.log('🔄 Migrando columna identificador a opcional...\n');

    // 1. Verificar estado actual
    console.log('📊 Estado actual de la tabla clientes:');
    const estadoActual = await pool.query(`
      SELECT 
        COUNT(*) as total_clientes,
        COUNT(identificador) as con_identificador,
        COUNT(ci_ruc) as con_ci_ruc
      FROM clientes
    `);
    
    const stats = estadoActual.rows[0];
    console.log(`  - Total clientes: ${stats.total_clientes}`);
    console.log(`  - Con identificador: ${stats.con_identificador}`);
    console.log(`  - Con ci_ruc: ${stats.con_ci_ruc}`);

    // 2. Migrar identificador a ci_ruc donde sea necesario
    console.log('\n🔄 Migrando identificador → ci_ruc...');
    const migracionIdentificador = await pool.query(`
      UPDATE clientes 
      SET ci_ruc = identificador 
      WHERE ci_ruc IS NULL AND identificador IS NOT NULL
    `);
    console.log(`✅ Migrados ${migracionIdentificador.rowCount} registros de identificador a ci_ruc`);

    // 3. Hacer la columna identificador opcional
    console.log('\n🔧 Haciendo identificador opcional...');
    await pool.query(`
      ALTER TABLE clientes ALTER COLUMN identificador DROP NOT NULL
    `);
    console.log('✅ Columna identificador ahora es opcional');

    // 4. Verificar estado final
    console.log('\n📊 Estado final después de la migración:');
    const estadoFinal = await pool.query(`
      SELECT 
        COUNT(*) as total_clientes,
        COUNT(identificador) as con_identificador,
        COUNT(ci_ruc) as con_ci_ruc
      FROM clientes
    `);
    
    const statsFinal = estadoFinal.rows[0];
    console.log(`  - Total clientes: ${statsFinal.total_clientes}`);
    console.log(`  - Con identificador: ${statsFinal.con_identificador}`);
    console.log(`  - Con ci_ruc: ${statsFinal.con_ci_ruc}`);

    console.log('\n🎉 Migración completada exitosamente!');
    console.log('✅ La columna identificador ahora es opcional');
    console.log('✅ Los datos se han migrado correctamente a ci_ruc');

  } catch (error) {
    console.error('❌ Error durante la migración:', error);
  } finally {
    await pool.end();
  }
}

migrarIdentificadorOpcional();
