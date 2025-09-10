class Publicacion {
  final String id;
  final String userId;
  final String autorNombre;
  final String titulo;
  final String contenido;
  final String tipo; // consejo, progreso, problema
  final DateTime fechaCreacion;
  final String estado; // activo, eliminado, moderado
  final int totalMeGusta;
  final int totalComentarios;
  final bool meGusta; // si el usuario actual le dio me gusta

  Publicacion({
    required this.id,
    required this.userId,
    required this.autorNombre,
    required this.titulo,
    required this.contenido,
    required this.tipo,
    required this.fechaCreacion,
    required this.estado,
    required this.totalMeGusta,
    required this.totalComentarios,
    required this.meGusta,
  });

  factory Publicacion.fromJson(Map<String, dynamic> json) {
    return Publicacion(
      id: json['id'],
      userId: json['user_id'],
      autorNombre: json['autor_nombre'],
      titulo: json['titulo'],
      contenido: json['contenido'],
      tipo: json['tipo'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      estado: json['estado'],
      totalMeGusta: json['total_me_gusta'],
      totalComentarios: json['total_comentarios'],
      meGusta: json['me_gusta'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'autor_nombre': autorNombre,
      'titulo': titulo,
      'contenido': contenido,
      'tipo': tipo,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'estado': estado,
      'total_me_gusta': totalMeGusta,
      'total_comentarios': totalComentarios,
      'me_gusta': meGusta,
    };
  }
}