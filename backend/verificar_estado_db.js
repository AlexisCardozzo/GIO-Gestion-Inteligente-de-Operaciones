require('dotenv').config({ path: 'configuracion.env' });
const pool = require('./config/database');

async function verificarEstadoBaseDeDatos() {
  try {
    console.log('🔍 Verificando estado actual de la base de datos...\n');
    
    // Lista de tablas principales
    const tablas = [
      'usuarios',
      'roles', 
      'sucursales',
      'clientes',
      'articulos',
      'ventas',
      'ventas_detalle',
      'stock_movimientos',
      'fidelizacion_campanias',
      'fidelizacion_requisitos',
      'fidelizacion_beneficios',
      'fidelizacion_clientes',
      'reportes'
    ];
    
    console.log('📊 Estado actual de las tablas:\n');
    
    let totalRegistros = 0;
    
    for (const tabla of tablas) {
      try {
        const result = await pool.query(`SELECT COUNT(*) as count FROM ${tabla};`);
        const count = parseInt(result.rows[0].count);
        totalRegistros += count;
        
        if (count > 0) {
          console.log(`📋 ${tabla}: ${count} registros`);
          
          // Mostrar algunos ejemplos de datos
          if (count <= 5) {
            const datos = await pool.query(`SELECT * FROM ${tabla} LIMIT 3;`);
            console.log(`   └─ Ejemplos: ${datos.rows.map(row => {
              if (row.nombre) return row.nombre;
              if (row.email) return row.email;
              if (row.id) return `ID: ${row.id}`;
              return 'Datos';
            }).join(', ')}`);
          } else {
            console.log(`   └─ (${count} registros totales)`);
          }
        } else {
          console.log(`📋 ${tabla}: 0 registros (vacía)`);
        }
      } catch (error) {
        console.log(`❌ ${tabla}: Error - ${error.message}`);
      }
    }
    
    console.log('\n📈 Resumen:');
    console.log(`   Total de registros en la base de datos: ${totalRegistros}`);
    
    if (totalRegistros > 0) {
      console.log('\n💡 Para limpiar la base de datos, ejecuta:');
      console.log('   node limpiar_db.js --confirm');
    } else {
      console.log('\n✅ La base de datos ya está limpia.');
    }
    
  } catch (error) {
    console.error('❌ Error verificando la base de datos:', error);
  } finally {
    await pool.end();
  }
}

verificarEstadoBaseDeDatos(); 