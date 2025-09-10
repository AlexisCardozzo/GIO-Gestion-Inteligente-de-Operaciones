import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FidelizacionService {
  static const String _baseUrl = 'http://127.0.0.1:3000/api/fidelizacion';

  // Función auxiliar para obtener el token de autenticación
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Función auxiliar para obtener headers con autenticación
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ===== CAMPAÑAS =====
  static Future<List<dynamic>> listarCampanias() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/campanias'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Error al obtener campañas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> listarTodasCampanias() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/campanias/todas'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Error al obtener todas las campañas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> listarCampaniasInactivas() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/campanias/inactivas'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Error al obtener campañas inactivas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>?> crearCampania({
    required String nombre,
    required String descripcion,
    required String fechaInicio,
    required String fechaFin,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/campanias'),
        headers: headers,
        body: json.encode({
          'nombre': nombre,
          'descripcion': descripcion,
          'fecha_inicio': fechaInicio,
          'fecha_fin': fechaFin,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al crear campaña');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>?> obtenerCampania(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/campanias/$id'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al obtener campaña');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>?> editarCampania({
    required int id,
    required String nombre,
    required String descripcion,
    required String fechaInicio,
    required String fechaFin,
    required bool activa,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/campanias/$id'),
        headers: headers,
        body: json.encode({
          'nombre': nombre,
          'descripcion': descripcion,
          'fecha_inicio': fechaInicio,
          'fecha_fin': fechaFin,
          'activa': activa,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al editar campaña');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<bool> eliminarCampania(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/campanias/$id'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===== REQUISITOS =====
  static Future<List<dynamic>> obtenerRequisitos(int campaniaId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/campanias/$campaniaId/requisitos'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Error al obtener requisitos');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<bool> agregarRequisito({
    required int campaniaId,
    required String tipo,
    required int valor,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/campanias/$campaniaId/requisitos'),
        headers: headers,
        body: json.encode({
          'tipo': tipo,
          'valor': valor,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> editarRequisito({
    required int id,
    required String tipo,
    required int valor,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/requisitos/$id'),
        headers: headers,
        body: json.encode({
          'tipo': tipo,
          'valor': valor,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> eliminarRequisito(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/requisitos/$id'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===== BENEFICIOS =====
  static Future<List<dynamic>> obtenerBeneficios(int campaniaId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/campanias/$campaniaId/beneficios'),
        headers: headers,
      );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Error al obtener beneficios');
    }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<bool> agregarBeneficio({
    required int campaniaId,
    required String tipo,
    required String valor,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/campanias/$campaniaId/beneficios'),
        headers: headers,
        body: json.encode({
          'tipo': tipo,
          'valor': valor,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> editarBeneficio({
    required int id,
    required String tipo,
    required String valor,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/beneficios/$id'),
        headers: headers,
        body: json.encode({
          'tipo': tipo,
          'valor': valor,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> eliminarBeneficio(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/beneficios/$id'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===== CLIENTES FIELES =====
  static Future<List<dynamic>> listarClientesFieles() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/clientes-fieles'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Error al obtener clientes fieles');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>?> obtenerClienteFiel(int clienteId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/clientes-fieles/$clienteId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al obtener cliente fiel');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== CANJEAR BENEFICIOS =====
  static Future<bool> canjearBeneficio(int clienteId, int beneficioId) async {
    try {
      final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/canjear'),
        headers: headers,
      body: json.encode({
        'cliente_id': clienteId,
        'beneficio_id': beneficioId,
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al canjear beneficio');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== ESTADÍSTICAS =====
  static Future<Map<String, dynamic>?> obtenerEstadisticas() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/estadisticas'),
        headers: headers,
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

  // ===== PROGRESO DEL BÚHO =====
  static Future<Map<String, dynamic>?> obtenerProgresoBuho() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/progreso-buho'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al obtener progreso del búho');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== PARTICIPANTES DE CAMPAÑA =====
  static Future<List<dynamic>> obtenerParticipantesCampania(int campaniaId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/campanias/$campaniaId/participantes'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Error al obtener participantes de la campaña');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== BENEFICIOS DISPONIBLES PARA CLIENTE =====
  static Future<Map<String, dynamic>?> obtenerBeneficiosDisponibles(int clienteId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/clientes/$clienteId/beneficios-disponibles'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al obtener beneficios disponibles');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== MÉTODOS LEGACY (para compatibilidad) =====
  static Future<List<dynamic>> listarBeneficios() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/beneficios'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Error al obtener beneficios');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== CLIENTES EN RIESGO =====
  static Future<List<dynamic>> listarClientesRiesgo() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/clientes-riesgo'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Error al obtener clientes en riesgo');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>?> analizarClientesRiesgo() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/clientes-riesgo/analizar'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al analizar clientes en riesgo');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>?> enviarMensajeRetencion({
    required int clienteId,
    required String mensaje,
    required int nivelRiesgo,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/clientes-riesgo/$clienteId/mensaje'),
        headers: headers,
        body: json.encode({
          'mensaje': mensaje,
          'nivel_riesgo': nivelRiesgo,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al enviar mensaje de retención');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>?> obtenerEstadisticasRetencion() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/clientes-riesgo/estadisticas'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al obtener estadísticas de retención');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>?> obtenerOpcionesMensaje(int clienteId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/clientes-riesgo/$clienteId/opciones-mensaje'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al obtener opciones de mensaje');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}