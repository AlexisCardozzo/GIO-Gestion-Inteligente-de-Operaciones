const fs = require('fs');
const path = require('path');

async function corregirEstadisticas() {
  try {
    console.log('🔧 Corrigiendo estadísticas...\n');
    
    const filePath = path.join(__dirname, 'controllers', 'fidelizacionController.js');
    let content = fs.readFileSync(filePath, 'utf8');
    
    // Corregir el error en la línea donde se procesan los niveles
    const oldLine = '        niveles[row.nivel] = parseInt(row.cantidad_clientes) || 0;';
    const newLine = '        niveles[row.nivel_fidelidad] = parseInt(row.cantidad_clientes) || 0;';
    
    if (content.includes(oldLine)) {
      content = content.replace(oldLine, newLine);
      console.log('✅ Corregido error en procesamiento de niveles');
    }
    
    // Guardar el archivo corregido
    fs.writeFileSync(filePath, content, 'utf8');
    console.log('✅ Archivo guardado correctamente');
    
  } catch (error) {
    console.error('❌ Error corrigiendo estadísticas:', error);
  }
}

corregirEstadisticas(); 