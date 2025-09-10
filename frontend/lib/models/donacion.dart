class Donacion {
  final int id;
  final int emprendedorId;
  final int? donanteId; // null si es anónimo
  final String? nombreDonante; // para donaciones anónimas
  final double monto;
  final double comisionGio;
  final double montoNeto;
  final String? mensaje;
  final bool anonimo;
  final String estado; // 'pendiente', 'procesada', 'completada', 'fallida'
  final DateTime fechaDonacion;
  final DateTime? fechaProcesamiento;
  final String? metodoPago;
  final String? referenciaPago;
  final String? agradecimiento;
  final DateTime? fechaAgradecimiento;

  Donacion({
    required this.id,
    required this.emprendedorId,
    this.donanteId,
    this.nombreDonante,
    required this.monto,
    required this.comisionGio,
    required this.montoNeto,
    this.mensaje,
    required this.anonimo,
    required this.estado,
    required this.fechaDonacion,
    this.fechaProcesamiento,
    this.metodoPago,
    this.referenciaPago,
    this.agradecimiento,
    this.fechaAgradecimiento,
  });

  factory Donacion.fromJson(Map<String, dynamic> json) {
    return Donacion(
      id: json['id'],
      emprendedorId: json['emprendedor_id'],
      donanteId: json['donante_id'],
      nombreDonante: json['nombre_donante'],
      monto: (json['monto'] ?? 0).toDouble(),
      comisionGio: (json['comision_gio'] ?? 0).toDouble(),
      montoNeto: (json['monto_neto'] ?? 0).toDouble(),
      mensaje: json['mensaje'],
      anonimo: json['anonimo'] ?? false,
      estado: json['estado'] ?? 'pendiente',
      fechaDonacion: DateTime.parse(json['fecha_donacion']),
      fechaProcesamiento: json['fecha_procesamiento'] != null 
          ? DateTime.parse(json['fecha_procesamiento']) 
          : null,
      metodoPago: json['metodo_pago'],
      referenciaPago: json['referencia_pago'],
      agradecimiento: json['agradecimiento'],
      fechaAgradecimiento: json['fecha_agradecimiento'] != null 
          ? DateTime.parse(json['fecha_agradecimiento']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emprendedor_id': emprendedorId,
      'donante_id': donanteId,
      'nombre_donante': nombreDonante,
      'monto': monto,
      'comision_gio': comisionGio,
      'monto_neto': montoNeto,
      'mensaje': mensaje,
      'anonimo': anonimo,
      'estado': estado,
      'fecha_donacion': fechaDonacion.toIso8601String(),
      'fecha_procesamiento': fechaProcesamiento?.toIso8601String(),
      'metodo_pago': metodoPago,
      'referencia_pago': referenciaPago,
      'agradecimiento': agradecimiento,
      'fecha_agradecimiento': fechaAgradecimiento?.toIso8601String(),
    };
  }

  String get nombreMostrar {
    if (anonimo) {
      return nombreDonante ?? 'Donante Anónimo';
    }
    return nombreDonante ?? 'Usuario GIO';
  }

  bool get tieneAgradecimiento => agradecimiento != null && agradecimiento!.isNotEmpty;
  
  String get estadoDisplay {
    switch (estado) {
      case 'pendiente': return 'Pendiente';
      case 'procesada': return 'Procesada';
      case 'completada': return 'Completada';
      case 'fallida': return 'Fallida';
      default: return 'Desconocido';
    }
  }

  double get porcentajeComision => monto > 0 ? (comisionGio / monto) * 100 : 0;
}
