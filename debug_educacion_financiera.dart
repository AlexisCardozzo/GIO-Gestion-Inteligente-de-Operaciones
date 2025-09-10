import 'dart:io';

void main() {
  print('🔍 Analizando archivo de educación financiera...\n');
  
  try {
    // Leer el archivo
    final file = File('lib/screens/educacion_financiera_screen_backup2.dart');
    final lines = file.readAsLinesSync();
    
    print('📊 Información del archivo:');
    print('   - Total de líneas: ${lines.length}');
    print('   - Tamaño: ${file.lengthSync()} bytes\n');
    
    // Buscar líneas problemáticas
    print('🔍 Buscando líneas problemáticas...\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;
      
      // Buscar patrones problemáticos
      if (line.contains('isMobile') && !line.contains('bool isMobile')) {
        print('⚠️  Línea $lineNumber: Variable isMobile no definida');
        print('   Contenido: ${line.trim()}');
        print('');
      }
      
      if (line.contains('_answerQuestion') && !line.contains('void _answerQuestion')) {
        print('⚠️  Línea $lineNumber: Método _answerQuestion no definido');
        print('   Contenido: ${line.trim()}');
        print('');
      }
      
      if (line.contains('_selectTrueFalse') && !line.contains('void _selectTrueFalse')) {
        print('⚠️  Línea $lineNumber: Método _selectTrueFalse no definido');
        print('   Contenido: ${line.trim()}');
        print('');
      }
      
      if (line.contains('trueFalseAnswer') && !line.contains('int trueFalseAnswer')) {
        print('⚠️  Línea $lineNumber: Variable trueFalseAnswer no definida');
        print('   Contenido: ${line.trim()}');
        print('');
      }
      
      // Buscar problemas de sintaxis
      if (line.trim().startsWith('},') && lineNumber > 1520 && lineNumber < 1530) {
        print('⚠️  Línea $lineNumber: Posible problema de sintaxis');
        print('   Contenido: ${line.trim()}');
        print('');
      }
    }
    
    // Verificar estructura de clases
    print('🔍 Verificando estructura de clases...\n');
    
    bool hasClass = false;
    bool hasIsMobile = false;
    bool hasAnswerQuestion = false;
    bool hasSelectTrueFalse = false;
    bool hasTrueFalseAnswer = false;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.contains('class EducacionFinancieraScreen')) {
        hasClass = true;
        print('✅ Clase encontrada en línea ${i + 1}');
      }
      
      if (line.contains('bool isMobile')) {
        hasIsMobile = true;
        print('✅ Variable isMobile definida en línea ${i + 1}');
      }
      
      if (line.contains('void _answerQuestion')) {
        hasAnswerQuestion = true;
        print('✅ Método _answerQuestion definido en línea ${i + 1}');
      }
      
      if (line.contains('void _selectTrueFalse')) {
        hasSelectTrueFalse = true;
        print('✅ Método _selectTrueFalse definido en línea ${i + 1}');
      }
      
      if (line.contains('int trueFalseAnswer')) {
        hasTrueFalseAnswer = true;
        print('✅ Variable trueFalseAnswer definida en línea ${i + 1}');
      }
    }
    
    print('\n📋 Resumen de problemas encontrados:');
    if (!hasClass) print('❌ No se encontró la clase EducacionFinancieraScreen');
    if (!hasIsMobile) print('❌ No se encontró la variable isMobile');
    if (!hasAnswerQuestion) print('❌ No se encontró el método _answerQuestion');
    if (!hasSelectTrueFalse) print('❌ No se encontró el método _selectTrueFalse');
    if (!hasTrueFalseAnswer) print('❌ No se encontró la variable trueFalseAnswer');
    
    if (hasClass && hasIsMobile && hasAnswerQuestion && hasSelectTrueFalse && hasTrueFalseAnswer) {
      print('✅ Todos los elementos principales están presentes');
    }
    
  } catch (e) {
    print('❌ Error al analizar el archivo: $e');
  }
} 