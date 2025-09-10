import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/emprendedor.dart';
import '../models/donacion.dart';

class FondoSolidarioService {
  static const String _baseUrl = 'http://localhost:3000/api/fondo-solidario';

  // Headers comunes con token de autenticación si está disponible
  static Future<Map<String, String>> get _headers async {
    return {
      'Content-Type': 'application/json',
    };
  }

  // ===== EMPRENDEDORES =====
  
  // Listar todos los emprendedores (admin)
  static Future<List<Emprendedor>> listarEmprendedores({String? estado}) async {
    try {
      String url = '$_baseUrl/emprendedores';
      if (estado != null) {
        url += '?estado=$estado';
      }
      
      final headers = await _headers;
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List).map((e) => Emprendedor.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener emprendedores');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Listar emprendedores verificados (público)
  static Future<List<Emprendedor>> listarEmprendedoresVerificados() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$_baseUrl/emprendedores/verificados'), 
        headers: headers
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List).map((e) => Emprendedor.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener emprendedores verificados');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener emprendedor por ID
  static Future<Emprendedor> obtenerEmprendedor(int id) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$_baseUrl/emprendedores/$id'), 
        headers: headers
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Emprendedor.fromJson(data['data']);
      } else {
        throw Exception('Error al obtener emprendedor');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Registrar solicitud de emprendedor
  static Future<Emprendedor> registrarEmprendedor(Map<String, dynamic> datos) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$_baseUrl/emprendedores'),
        headers: headers,
        body: json.encode(datos),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Emprendedor.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al registrar emprendedor');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar emprendedor
  static Future<Emprendedor> actualizarEmprendedor(int id, Map<String, dynamic> datos) async {
    try {
      final headers = await _headers;
      final response = await http.put(
        Uri.parse('$_baseUrl/emprendedores/$id'),
        headers: headers,
        body: json.encode(datos),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Emprendedor.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al actualizar emprendedor');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Verificar emprendedor (admin)
  static Future<Emprendedor> verificarEmprendedor(int id, String estado, {String? motivoRechazo}) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$_baseUrl/emprendedores/$id/verificar'),
        headers: headers,
        body: json.encode({
          'estado': estado,
          'motivo_rechazo': motivoRechazo,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Emprendedor.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al verificar emprendedor');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== DONACIONES =====

  // Listar donaciones de un emprendedor
  static Future<List<Donacion>> listarDonacionesEmprendedor(int emprendedorId) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$_baseUrl/emprendedores/$emprendedorId/donaciones'), 
        headers: headers
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List).map((e) => Donacion.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener donaciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Listar donaciones de un usuario
  static Future<List<Donacion>> listarDonacionesUsuario(int usuarioId) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$_baseUrl/usuarios/$usuarioId/donaciones'), 
        headers: headers
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List).map((e) => Donacion.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener donaciones del usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Realizar donación
  static Future<Donacion> realizarDonacion(Map<String, dynamic> datos) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$_baseUrl/donaciones'),
        headers: headers,
        body: json.encode(datos),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Donacion.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al realizar donación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Agregar agradecimiento a una donación
  static Future<Donacion> agregarAgradecimiento(int donacionId, String agradecimiento) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$_baseUrl/donaciones/$donacionId/agradecimiento'),
        headers: headers,
        body: json.encode({'agradecimiento': agradecimiento}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Donacion.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al agregar agradecimiento');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== ESTADÍSTICAS =====

  // Obtener estadísticas generales
  static Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$_baseUrl/estadisticas'), 
        headers: headers
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al obtener estadísticas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener estadísticas de un emprendedor
  static Future<Map<String, dynamic>> obtenerEstadisticasEmprendedor(int emprendedorId) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$_baseUrl/emprendedores/$emprendedorId/estadisticas'), 
        headers: headers
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al obtener estadísticas del emprendedor');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== ADMINISTRACIÓN =====

  // Listar todas las donaciones (admin)
  static Future<List<Donacion>> listarTodasDonaciones({String? estado}) async {
    try {
      String url = '$_baseUrl/admin/donaciones';
      if (estado != null) {
        url += '?estado=$estado';
      }
      
      final headers = await _headers;
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List).map((e) => Donacion.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener donaciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Procesar donación (admin)
  static Future<Donacion> procesarDonacion(int donacionId, String estado) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$_baseUrl/admin/donaciones/$donacionId/procesar'),
        headers: headers,
        body: json.encode({'estado': estado}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Donacion.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al procesar donación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
