const fs = require('fs');
const path = require('path');

async function corregirControlador() {
  try {
    console.log('🔧 Corrigiendo controlador de fidelización...\n');
    
    const filePath = path.join(__dirname, 'controllers', 'fidelizacionController.js');
    let content = fs.readFileSync(filePath, 'utf8');
    
    // Corregir GROUP BY en listarClientesFieles
    const oldGroupBy1 = 'GROUP BY c.id, c.nombre, c.ci_ruc, c.celular';
    const newGroupBy1 = 'GROUP BY c.id, c.nombre, c.ci_ruc, c.celular, fcl.puntos_acumulados';
    
    if (content.includes(oldGroupBy1)) {
      content = content.replace(oldGroupBy1, newGroupBy1);
      console.log('✅ Corregido GROUP BY en listarClientesFieles');
    }
    
    // Corregir GROUP BY en obtenerClienteFiel
    const oldGroupBy2 = 'WHERE c.id = $1 AND c.activo = true\n        GROUP BY c.id, c.nombre, c.ci_ruc, c.celular';
    const newGroupBy2 = 'WHERE c.id = $1 AND c.activo = true\n        GROUP BY c.id, c.nombre, c.ci_ruc, c.celular, fcl.puntos_acumulados';
    
    if (content.includes(oldGroupBy2)) {
      content = content.replace(oldGroupBy2, newGroupBy2);
      console.log('✅ Corregido GROUP BY en obtenerClienteFiel');
    }
    
    // Guardar el archivo corregido
    fs.writeFileSync(filePath, content, 'utf8');
    console.log('✅ Archivo guardado correctamente');
    
  } catch (error) {
    console.error('❌ Error corrigiendo controlador:', error);
  }
}

corregirControlador(); 