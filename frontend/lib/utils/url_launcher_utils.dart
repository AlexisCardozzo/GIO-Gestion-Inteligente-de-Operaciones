import 'dart:async' show Future;  
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../config/environment_config.dart';
import 'logger_service.dart';

/// Clase para gestionar la apertura de URLs en diferentes plataformas y entornos
class UrlLauncherService {
  /// Singleton instance
  static final UrlLauncherService _instance = UrlLauncherService._internal();
  
  /// Factory constructor para obtener la instancia singleton
  factory UrlLauncherService() => _instance;
  
  /// Referencia a la configuración de entorno
  final EnvironmentConfig _config = EnvironmentConfig();
  
  /// Constructor privado
  UrlLauncherService._internal();
  
  /// Convierte una URL relativa a absoluta según el entorno
  String _getAbsoluteUrl(String url) {
    // Si ya es una URL absoluta, la devolvemos tal cual
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // Utilizamos la configuración centralizada para construir la URL
    return _config.buildApiUrl(url);
  }
  
  /// Abre una URL en cualquier plataforma
  Future<bool> openUrl(String url, {bool forceExternalBrowser = false}) async {
    // Convertimos a URL absoluta si es necesario
    final absoluteUrl = _getAbsoluteUrl(url);
    final uri = Uri.parse(absoluteUrl);
    
    try {
      if (await url_launcher.canLaunchUrl(uri)) {
        // Elegimos el modo de lanzamiento según la plataforma y preferencias
        final launchMode = _determineLaunchMode(forceExternalBrowser);
        
        // Registramos la acción en el log
        logger.info('Abriendo URL: $absoluteUrl con modo: ${launchMode.toString()}');
        
        return await url_launcher.launchUrl(uri, mode: launchMode);
      } else {
        // Registramos el error en el log
        logger.warning('No se pudo abrir la URL: $absoluteUrl', 
            error: 'La URL no puede ser lanzada por el sistema');
        return false;
      }
    } catch (e, stackTrace) {
      // Registramos la excepción en el log
      logger.error('Error al abrir URL: $absoluteUrl', 
          error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Determina el modo de lanzamiento según la plataforma y preferencias
  url_launcher.LaunchMode _determineLaunchMode(bool forceExternalBrowser) {
    if (forceExternalBrowser) {
      return url_launcher.LaunchMode.externalApplication;
    }
    
    if (kIsWeb) {
      // En web, siempre usamos una nueva pestaña
      return url_launcher.LaunchMode.externalApplication;
    }
    
    // En móvil, por defecto usamos el navegador in-app si está disponible
    return url_launcher.LaunchMode.platformDefault;
  }
}

/// Función auxiliar global para mantener compatibilidad con el código existente
Future<bool> openUrl(String url) async {
  return await UrlLauncherService().openUrl(url);
}