import 'package:flutter/foundation.dart' show kDebugMode;

/// Niveles de log soportados
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Servicio de logging para la aplicación
class LoggerService {
  /// Singleton instance
  static final LoggerService _instance = LoggerService._internal();
  
  /// Factory constructor para obtener la instancia singleton
  factory LoggerService() => _instance;
  
  /// Constructor privado
  LoggerService._internal();

  /// Nivel mínimo de log que se mostrará
  /// En producción, podría configurarse para mostrar solo warnings y errores
  final LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;

  /// Método principal de logging
  void log(String message, {LogLevel level = LogLevel.info, Object? error, StackTrace? stackTrace}) {
    // Solo mostramos logs del nivel configurado o superior
    if (level.index < _minLevel.index) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();
    final logMessage = '[$timestamp] $levelStr: $message';
    
    // En una implementación real, podríamos enviar logs a un servicio externo
    // o guardarlos en un archivo según el entorno
    
    // Por ahora, simplemente imprimimos en consola
    print(logMessage);
    
    if (error != null) {
      print('ERROR: $error');
      if (stackTrace != null) {
        print('STACK TRACE: $stackTrace');
      }
    }
  }

  /// Métodos de conveniencia para cada nivel de log
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.debug, error: error, stackTrace: stackTrace);
  }

  void info(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.info, error: error, stackTrace: stackTrace);
  }

  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.warning, error: error, stackTrace: stackTrace);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);
  }

  void critical(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.critical, error: error, stackTrace: stackTrace);
  }
}

/// Instancia global para facilitar el acceso al logger
final logger = LoggerService();