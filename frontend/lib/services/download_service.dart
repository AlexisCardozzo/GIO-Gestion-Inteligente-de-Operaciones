import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/environment_config.dart';
import '../utils/logger_service.dart';
import '../utils/url_launcher_utils.dart';

/// Servicio para gestionar la descarga de archivos
class DownloadService {
  /// Singleton instance
  static final DownloadService _instance = DownloadService._internal();
  
  /// Factory constructor para obtener la instancia singleton
  factory DownloadService() => _instance;
  
  /// Referencia a la configuración de entorno
  final EnvironmentConfig _config = EnvironmentConfig();
  
  /// Referencia al servicio de URL Launcher
  final UrlLauncherService _urlLauncher = UrlLauncherService();
  
  /// Constructor privado
  DownloadService._internal();

  /// Cabeceras comunes para todas las peticiones
  Map<String, String> get _commonHeaders => {
    'Accept': '*/*',
  };

  /// Añade el token de autenticación a las cabeceras si está disponible
  Map<String, String> _getHeaders(Map<String, String>? additionalHeaders) {
    final headers = Map<String, String>.from(_commonHeaders);
    
    // TODO: Implementar lógica para obtener el token de autenticación
    // final authToken = AuthService().token;
    // if (authToken != null) {
    //   headers['Authorization'] = 'Bearer $authToken';
    // }
    
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    
    return headers;
  }

  /// Descarga un archivo usando URL Launcher (abre en el navegador)
  /// Este método es compatible con todas las plataformas
  Future<bool> downloadFileWithUrlLauncher(String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    bool forceExternalBrowser = false,
  }) async {
    try {
      // Construimos la URL completa
      final url = _config.buildApiUrl(endpoint);
      
      logger.info('Iniciando descarga de archivo con URL Launcher: $url');
      
      // Usamos el servicio de URL Launcher para abrir la URL
      final result = await _urlLauncher.openUrl(
        url, 
        forceExternalBrowser: forceExternalBrowser,
      );
      
      if (result) {
        logger.info('Descarga iniciada correctamente');
      } else {
        logger.warning('No se pudo iniciar la descarga');
      }
      
      return result;
    } catch (e, stackTrace) {
      logger.error('Error al descargar archivo: $endpoint', 
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Descarga un archivo y devuelve los bytes
  /// Útil para plataformas móviles donde queremos guardar el archivo localmente
  Future<Uint8List?> downloadFileAsBytes(String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      // Construimos la URL completa
      final uri = Uri.parse(_config.buildApiUrl(endpoint)).replace(
        queryParameters: queryParams,
      );
      
      logger.info('Descargando archivo como bytes: $uri');
      
      final response = await http.get(
        uri,
        headers: _getHeaders(headers),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        logger.info('Archivo descargado correctamente: ${response.contentLength} bytes');
        return response.bodyBytes;
      } else {
        logger.error('Error al descargar archivo: ${response.statusCode}', 
            error: response.body);
        return null;
      }
    } catch (e, stackTrace) {
      logger.error('Error al descargar archivo como bytes: $endpoint', 
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Método para descargar un ticket XML
  /// Este es un método específico para la funcionalidad que estamos mejorando
  Future<bool> downloadTicketXml(dynamic ventaId, {
    bool forceExternalBrowser = false,
  }) async {
    if (ventaId == null) {
      logger.error('No se puede descargar el ticket XML: ID de venta es nulo');
      return false;
    }
    
    final endpoint = '/api/ventas/$ventaId/ticket-xml';
    return await downloadFileWithUrlLauncher(
      endpoint,
      forceExternalBrowser: forceExternalBrowser,
    );
  }
}

/// Instancia global para facilitar el acceso al servicio de descargas
final downloadService = DownloadService();