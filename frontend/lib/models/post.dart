class Post {
  final int id;
  final int usuarioId;
  final String autorNombre;
  final String autorEmail;
  final String contenido;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final int likesCount;
  final int comentariosCount;
  final bool isComentario;
  final int? postPadreId;
  final List<String> hashtags;
  final List<Post> comentarios;
  final bool liked;
  final String? categoria;

  Post({
    required this.id,
    required this.usuarioId,
    required this.autorNombre,
    required this.autorEmail,
    required this.contenido,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.likesCount,
    required this.comentariosCount,
    this.isComentario = false,
    this.postPadreId,
    this.hashtags = const [],
    this.comentarios = const [],
    this.liked = false,
    this.categoria,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      usuarioId: json['usuario_id'],
      autorNombre: json['autor_nombre'],
      autorEmail: json['autor_email'],
      contenido: json['contenido'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaActualizacion: DateTime.parse(json['fecha_actualizacion']),
      likesCount: json['likes_count'] ?? 0,
      comentariosCount: json['comentarios_count'] ?? 0,
      isComentario: json['is_comentario'] ?? false,
      postPadreId: json['post_padre_id'],
      hashtags: (json['hashtags'] as List?)
              ?.map((h) => h['nombre'].toString())
              .toList() ??
          [],
      comentarios: (json['comentarios'] as List?)
              ?.map((c) => Post.fromJson(c))
              .toList() ??
          [],
      liked: json['liked'] ?? false,
      categoria: json['categoria'],
    );
  }
}

class PostFeedResult {
  final List<Post> posts;
  final bool hasMore;

  PostFeedResult({
    required this.posts,
    required this.hasMore,
  });
}

class Notificacion {
  final int id;
  final int usuarioId;
  final String tipo;
  final String contenido;
  final bool leida;
  final DateTime fechaCreacion;
  final int? referenciaId;
  final String? referenciaTipo;

  Notificacion({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.contenido,
    required this.leida,
    required this.fechaCreacion,
    this.referenciaId,
    this.referenciaTipo,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'],
      usuarioId: json['usuario_id'],
      tipo: json['tipo'],
      contenido: json['contenido'],
      leida: json['leida'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      referenciaId: json['referencia_id'],
      referenciaTipo: json['referencia_tipo'],
    );
  }
}
