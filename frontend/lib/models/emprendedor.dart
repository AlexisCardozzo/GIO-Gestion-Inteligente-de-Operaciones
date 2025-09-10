class Emprendedor {
  final int id;
  final int? userId; // ID del usuario que es emprendedor
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String? fotoPerfil;
  final String? fotoPortada;
  final String? videoUrl;
  final String historia;
  final String? metaDescripcion;
  final double metaRecaudacion;
  final double recaudado;
  final bool verificado;
  final String estado; // 'pendiente', 'aprobado', 'rechazado', 'suspendido'
  final DateTime fechaRegistro;
  final DateTime? fechaVerificacion;
  final String? motivoRechazo;
  final String? categoria;
  final String? ubicacion;

  Emprendedor({
    required this.id,
    this.userId,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    this.fotoPerfil,
    this.fotoPortada,
    this.videoUrl,
    required this.historia,
    this.metaDescripcion,
    required this.metaRecaudacion,
    required this.recaudado,
    required this.verificado,
    required this.estado,
    required this.fechaRegistro,
    this.fechaVerificacion,
    this.motivoRechazo,
    this.categoria,
    this.ubicacion,
  });

  factory Emprendedor.fromJson(Map<String, dynamic> json) {
    return Emprendedor(
      id: json['id'],
      userId: json['user_id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      email: json['email'],
      telefono: json['telefono'],
      fotoPerfil: json['foto_perfil'],
      fotoPortada: json['foto_portada'],
      videoUrl: json['video_url'],
      historia: json['historia'],
      metaDescripcion: json['meta_descripcion'],
      metaRecaudacion: (json['meta_recaudacion'] ?? 0).toDouble(),
      recaudado: (json['recaudado'] ?? 0).toDouble(),
      verificado: json['verificado'] ?? false,
      estado: json['estado'] ?? 'pendiente',
      fechaRegistro: DateTime.parse(json['fecha_registro']),
      fechaVerificacion: json['fecha_verificacion'] != null 
          ? DateTime.parse(json['fecha_verificacion']) 
          : null,
      motivoRechazo: json['motivo_rechazo'],
      categoria: json['categoria'],
      ubicacion: json['ubicacion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'foto_perfil': fotoPerfil,
      'foto_portada': fotoPortada,
      'video_url': videoUrl,
      'historia': historia,
      'meta_descripcion': metaDescripcion,
      'meta_recaudacion': metaRecaudacion,
      'recaudado': recaudado,
      'verificado': verificado,
      'estado': estado,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'fecha_verificacion': fechaVerificacion?.toIso8601String(),
      'motivo_rechazo': motivoRechazo,
      'categoria': categoria,
      'ubicacion': ubicacion,
    };
  }

  String get nombreCompleto => '$nombre $apellido';
  
  double get progresoRecaudacion => metaRecaudacion > 0 ? recaudado / metaRecaudacion : 0;
  
  bool get puedeRecibirDonaciones => verificado && estado == 'aprobado';
  
  String get estadoDisplay {
    switch (estado) {
      case 'pendiente': return 'Pendiente de revisión';
      case 'aprobado': return 'Aprobado';
      case 'rechazado': return 'Rechazado';
      case 'suspendido': return 'Suspendido';
      default: return 'Desconocido';
    }
  }
}
