import 'package:dio/dio.dart';
import '../models/post.dart';
import '../config/api.dart';

class PostService {
  static final _dio = Dio(BaseOptions(
    baseURL: Api.baseUrl,
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  // Crear un nuevo post
  static Future<Post> crear(String contenido, {String? categoria}) async {
    try {
      final response = await _dio.post('/posts', data: {
        'contenido': contenido,
        'categoria': categoria,
      });

      return Post.fromJson(response.data['data']);
    } catch (e) {
      throw _manejarError(e);
    }
  }

  // Obtener feed de posts
  static Future<PostFeedResult> obtenerFeed({
    int page = 1,
    int limit = 20,
    String? categoria,
  }) async {
    try {
      final response = await _dio.get(
        '/posts/feed',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (categoria != null) 'categoria': categoria,
        },
      );

      final data = response.data;
      return PostFeedResult(
        posts: (data['data'] as List)
            .map((json) => Post.fromJson(json))
            .toList(),
        hasMore: data['pagination']['hasMore'],
      );
    } catch (e) {
      throw _manejarError(e);
    }
  }

  // Dar/quitar like a un post
  static Future<bool> toggleLike(int postId) async {
    try {
      final response = await _dio.post('/posts/$postId/like');
      return response.data['data']['liked'];
    } catch (e) {
      throw _manejarError(e);
    }
  }

  // Comentar en un post
  static Future<Post> comentar(int postId, String contenido) async {
    try {
      final response = await _dio.post(
        '/posts/$postId/comentarios',
        data: {'contenido': contenido},
      );
      return Post.fromJson(response.data['data']);
    } catch (e) {
      throw _manejarError(e);
    }
  }

  // Obtener notificaciones
  static Future<List<Notificacion>> obtenerNotificaciones({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/posts/notificaciones',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return (response.data['data'] as List)
          .map((json) => Notificacion.fromJson(json))
          .toList();
    } catch (e) {
      throw _manejarError(e);
    }
  }

  // Obtener hashtags trending
  static Future<List<Map<String, dynamic>>> obtenerTrendingHashtags() async {
    try {
      final response = await _dio.get('/posts/trending');
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (e) {
      throw _manejarError(e);
    }
  }

  // Manejar errores de la API
  static Exception _manejarError(dynamic error) {
    if (error is DioError) {
      if (error.response?.data != null) {
        return Exception(error.response?.data['error'] ?? 'Error del servidor');
      }
      return Exception(error.message ?? 'Error de conexión');
    }
    return Exception('Error inesperado');
  }
}
