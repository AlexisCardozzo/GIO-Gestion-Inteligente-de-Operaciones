const pool = require('./config/database');

async function consolidarTablasDetalle() {
  try {
    console.log('🔧 Consolidando tablas de detalles de ventas...\n');

    // 1. Verificar estructura de las tablas
    console.log('📋 Estructura de las tablas:');
    
    const tablas = ['detalle_venta', 'detalle_ventas', 'ventas_detalle'];
    
    for (const tabla of tablas) {
      try {
        const estructura = await pool.query(`
          SELECT column_name, data_type, is_nullable
          FROM information_schema.columns 
          WHERE table_name = $1
          ORDER BY ordinal_position
        `, [tabla]);
        
        console.log(`\n${tabla}:`);
        estructura.rows.forEach(col => {
          console.log(`  - ${col.column_name}: ${col.data_type} (${col.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
        });
      } catch (error) {
        console.log(`\n${tabla}: No existe`);
      }
    }

    // 2. Verificar datos en cada tabla
    console.log('\n📊 Datos en cada tabla:');
    
    for (const tabla of tablas) {
      try {
        const count = await pool.query(`SELECT COUNT(*) as count FROM ${tabla}`);
        console.log(`  - ${tabla}: ${count.rows[0].count} registros`);
        
        if (count.rows[0].count > 0) {
          const sample = await pool.query(`SELECT * FROM ${tabla} LIMIT 3`);
          console.log(`    Muestra:`, sample.rows);
        }
      } catch (error) {
        console.log(`  - ${tabla}: Error - ${error.message}`);
      }
    }

    // 3. Decidir qué tabla usar como estándar
    console.log('\n🎯 Decisión: Usaremos "ventas_detalle" como tabla estándar');
    
    // 4. Migrar datos de detalle_ventas a ventas_detalle si es necesario
    try {
      const detalleVentasCount = await pool.query('SELECT COUNT(*) as count FROM detalle_ventas');
      
      if (detalleVentasCount.rows[0].count > 0) {
        console.log('\n🔄 Migrando datos de detalle_ventas a ventas_detalle...');
        
        // Verificar si hay conflictos
        const conflictos = await pool.query(`
          SELECT dv.venta_id, dv.producto_id
          FROM detalle_ventas dv
          INNER JOIN ventas_detalle vd ON dv.venta_id = vd.venta_id AND dv.producto_id = vd.producto_id
        `);
        
        if (conflictos.rows.length > 0) {
          console.log(`⚠️ Encontrados ${conflictos.rows.length} conflictos. Los datos ya existen en ventas_detalle.`);
        }
        
        // Migrar solo los que no existen
        const migracion = await pool.query(`
          INSERT INTO ventas_detalle (venta_id, producto_id, cantidad, precio_unitario, subtotal)
          SELECT dv.venta_id, dv.producto_id, dv.cantidad, dv.precio_unitario, dv.subtotal
          FROM detalle_ventas dv
          WHERE NOT EXISTS (
            SELECT 1 FROM ventas_detalle vd 
            WHERE vd.venta_id = dv.venta_id AND vd.producto_id = dv.producto_id
          )
        `);
        
        console.log(`✅ Migrados ${migracion.rowCount} registros únicos`);
      }
    } catch (error) {
      console.log('⚠️ Error en migración:', error.message);
    }

    // 5. Actualizar el modelo Venta.js para usar ventas_detalle
    console.log('\n📝 Actualizando modelo Venta.js...');
    
    // Leer el archivo actual
    const fs = require('fs');
    const path = require('path');
    const ventaModelPath = path.join(__dirname, 'models', 'Venta.js');
    
    if (fs.existsSync(ventaModelPath)) {
      let contenido = fs.readFileSync(ventaModelPath, 'utf8');
      
      // Reemplazar todas las referencias a detalle_ventas por ventas_detalle
      const contenidoActualizado = contenido.replace(/detalle_ventas/g, 'ventas_detalle');
      
      // Crear backup
      fs.writeFileSync(ventaModelPath + '.backup', contenido);
      
      // Escribir archivo actualizado
      fs.writeFileSync(ventaModelPath, contenidoActualizado);
      
      console.log('✅ Modelo Venta.js actualizado');
      console.log('📄 Backup creado en Venta.js.backup');
    } else {
      console.log('❌ No se encontró el archivo Venta.js');
    }

    // 6. Verificar resultado final
    console.log('\n📊 Verificación final:');
    
    const ventasDetalleCount = await pool.query('SELECT COUNT(*) as count FROM ventas_detalle');
    console.log(`  - ventas_detalle: ${ventasDetalleCount.rows[0].count} registros`);
    
    // Verificar ventas sin detalles
    const ventasSinDetalles = await pool.query(`
      SELECT v.id, v.fecha, v.total
      FROM ventas v
      LEFT JOIN ventas_detalle vd ON v.id = vd.venta_id
      WHERE vd.venta_id IS NULL
      ORDER BY v.fecha DESC
      LIMIT 5
    `);
    
    if (ventasSinDetalles.rows.length > 0) {
      console.log('\n⚠️ Ventas sin detalles:');
      ventasSinDetalles.rows.forEach(venta => {
        console.log(`  - Venta ${venta.id} (${venta.fecha}): $${venta.total}`);
      });
    } else {
      console.log('\n✅ Todas las ventas tienen detalles');
    }

    console.log('\n🎉 Consolidación completada!');
    console.log('💡 Ahora todas las referencias usan "ventas_detalle" como tabla estándar');

  } catch (error) {
    console.error('❌ Error en consolidación:', error);
  } finally {
    await pool.end();
  }
}

consolidarTablasDetalle(); 