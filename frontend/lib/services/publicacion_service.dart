import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/publicacion.dart';
import '../config/api_config.dart';
import '../utils/http_utils.dart';

class PublicacionService {
  static const String _baseUrl = ApiConfig.baseUrl;

  // Listar publicaciones
  static Future<List<Publicacion>> listarPublicaciones() async {
    try {
      final response = await HttpUtils.get('/api/publicaciones');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Publicacion.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar publicaciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener publicación por ID
  static Future<Publicacion> obtenerPublicacion(int id) async {
    try {
      final response = await HttpUtils.get('/api/publicaciones/$id');
      
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body)['data'];
        return Publicacion.fromJson(data);
      } else {
        throw Exception('Error al obtener publicación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear publicación
  static Future<void> crearPublicacion(Map<String, dynamic> datos) async {
    try {
      final response = await HttpUtils.post('/api/publicaciones', datos);

      if (response.statusCode != 201) {
        throw Exception('Error al crear publicación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar publicación
  static Future<void> actualizarPublicacion(int id, Map<String, dynamic> datos) async {
    try {
      final response = await HttpUtils.put('/api/publicaciones/$id', datos);
      
      if (response.statusCode != 200) {
        throw Exception('Error al actualizar publicación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Dar/quitar me gusta
  static Future<void> toggleMeGusta(String publicacionId) async {
    try {
      final response = await HttpUtils.post('/api/publicaciones/$publicacionId/me-gusta', {});

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar me gusta');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Agregar comentario
  static Future<void> agregarComentario(String publicacionId, String comentario) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/publicaciones/$publicacionId/comentarios'),
        headers: await HttpUtils.getAuthHeaders(),
        body: json.encode({'contenido': comentario}),
      );

      if (response.statusCode != 201) {
        throw Exception('Error al agregar comentario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Listar comentarios de una publicación
  static Future<List<Map<String, dynamic>>> listarComentarios(String publicacionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/publicaciones/$publicacionId/comentarios'),
        headers: await HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error al cargar comentarios');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar publicación (solo para el autor o administradores)
  static Future<void> eliminarPublicacion(String publicacionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/publicaciones/$publicacionId'),
        headers: await HttpUtils.getAuthHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar publicación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Reportar publicación
  static Future<void> reportarPublicacion(String publicacionId, String motivo) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/publicaciones/$publicacionId/reportar'),
        headers: await HttpUtils.getAuthHeaders(),
        body: json.encode({'motivo': motivo}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al reportar publicación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}