/// Tipos de entorno soportados
enum AppEnvironment {
  development,
  staging,
  production,
}

/// Clase para gestionar la configuración de entorno de la aplicación
class EnvironmentConfig {
  /// Singleton instance
  static final EnvironmentConfig _instance = EnvironmentConfig._internal();
  
  /// Factory constructor para obtener la instancia singleton
  factory EnvironmentConfig() => _instance;
  
  /// Constructor privado
  EnvironmentConfig._internal();

  /// Entorno actual
  /// En una implementación real, esto podría determinarse en tiempo de compilación
  /// o mediante variables de entorno
  final AppEnvironment _currentEnvironment = AppEnvironment.development;

  /// Getter para el entorno actual
  AppEnvironment get currentEnvironment => _currentEnvironment;

  /// Verifica si estamos en entorno de desarrollo
  bool get isDevelopment => _currentEnvironment == AppEnvironment.development;

  /// Verifica si estamos en entorno de staging
  bool get isStaging => _currentEnvironment == AppEnvironment.staging;

  /// Verifica si estamos en entorno de producción
  bool get isProduction => _currentEnvironment == AppEnvironment.production;

  /// URL base de la API según el entorno
  String get apiBaseUrl {
    switch (_currentEnvironment) {
      case AppEnvironment.development:
        return 'http://localhost:3000';
      case AppEnvironment.staging:
        return 'https://staging-api.tudominio.com';
      case AppEnvironment.production:
        return 'https://api.tudominio.com';
    }
  }

  /// Método para construir una URL completa a partir de una ruta relativa
  String buildApiUrl(String path) {
    // Aseguramos que la ruta comience con /
    final relativePath = path.startsWith('/') ? path : '/$path';
    return '$apiBaseUrl$relativePath';
  }
}