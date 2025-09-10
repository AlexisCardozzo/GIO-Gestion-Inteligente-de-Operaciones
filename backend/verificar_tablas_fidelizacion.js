require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function verificarTablasFidelizacion() {
  try {
    console.log('🔍 Verificando estructura de tablas de fidelización...\n');
    
    const tablas = [
      'fidelizacion_campanias',
      'fidelizacion_requisitos', 
      'fidelizacion_beneficios',
      'fidelizacion_clientes'
    ];
    
    for (const tabla of tablas) {
      console.log(`📋 Tabla: ${tabla}`);
      
      // Verificar si existe
      const existeResult = await pool.query(`
        SELECT EXISTS (
          SELECT FROM information_schema.tables 
          WHERE table_schema = 'public' 
          AND table_name = $1
        );
      `, [tabla]);
      
      if (!existeResult.rows[0].exists) {
        console.log(`  ❌ La tabla ${tabla} no existe`);
        continue;
      }
      
      // Obtener estructura
      const columnsResult = await pool.query(`
        SELECT 
          column_name,
          data_type,
          is_nullable,
          column_default
        FROM information_schema.columns 
        WHERE table_name = $1 
        ORDER BY ordinal_position;
      `, [tabla]);
      
      console.log(`  ✅ Estructura:`);
      columnsResult.rows.forEach(column => {
        console.log(`    - ${column.column_name}: ${column.data_type} ${column.is_nullable === 'NO' ? '(NOT NULL)' : '(NULL)'} ${column.column_default ? `DEFAULT: ${column.column_default}` : ''}`);
      });
      
      // Contar registros
      const countResult = await pool.query(`SELECT COUNT(*) as total FROM ${tabla}`);
      console.log(`  📊 Total registros: ${countResult.rows[0].total}`);
      
      // Mostrar algunos ejemplos
      const sampleResult = await pool.query(`SELECT * FROM ${tabla} LIMIT 2`);
      if (sampleResult.rows.length > 0) {
        console.log(`  📝 Ejemplos:`);
        sampleResult.rows.forEach((row, index) => {
          console.log(`    ${index + 1}. ${JSON.stringify(row)}`);
        });
      }
      
      console.log('');
    }
    
  } catch (error) {
    console.error('❌ Error verificando tablas:', error);
  } finally {
    await pool.end();
  }
}

verificarTablasFidelizacion(); 