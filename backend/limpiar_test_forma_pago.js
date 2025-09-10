const pool = require('./config/database');

async function limpiarTestFormaPago() {
  try {
    console.log('🧹 Limpiando datos de prueba de formas de pago...\n');

    // Eliminar ventas de prueba
    const deleteVentasQuery = `
      DELETE FROM ventas 
      WHERE cliente_id IN (
        SELECT id FROM clientes WHERE nombre = 'Cliente Test Forma Pago'
      )
    `;
    
    const ventasResult = await pool.query(deleteVentasQuery);
    console.log(`✅ ${ventasResult.rowCount} ventas de prueba eliminadas`);

    // Eliminar cliente de prueba
    const deleteClienteQuery = `
      DELETE FROM clientes 
      WHERE nombre = 'Cliente Test Forma Pago'
    `;
    
    const clienteResult = await pool.query(deleteClienteQuery);
    console.log(`✅ ${clienteResult.rowCount} cliente de prueba eliminado`);

    console.log('\n🎉 Limpieza completada exitosamente!');

  } catch (error) {
    console.error('❌ Error limpiando datos:', error);
  } finally {
    await pool.end();
  }
}

limpiarTestFormaPago(); 