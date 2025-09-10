const fs = require('fs');
const path = require('path');

async function agregarImagenPubspec() {
  try {
    console.log('🔧 Agregando imagen al pubspec.yaml...\n');
    
    const filePath = path.join(__dirname, 'pubspec.yaml');
    let content = fs.readFileSync(filePath, 'utf8');
    
    // Buscar la línea donde está fondoprincipal.png y agregar este.quiero.png después
    const oldLine = '  - assets/fondoprincipal.png';
    const newLine = '  - assets/fondoprincipal.png\n    - assets/este.quiero.png';
    
    if (content.includes(oldLine) && !content.includes('assets/este.quiero.png')) {
      content = content.replace(oldLine, newLine);
      console.log('✅ Imagen agregada al pubspec.yaml');
    } else if (content.includes('assets/este.quiero.png')) {
      console.log('✅ La imagen ya está en el pubspec.yaml');
    } else {
      console.log('❌ No se encontró la línea de fondoprincipal.png');
    }
    
    // Guardar el archivo
    fs.writeFileSync(filePath, content, 'utf8');
    console.log('✅ Archivo guardado correctamente');
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

agregarImagenPubspec(); 