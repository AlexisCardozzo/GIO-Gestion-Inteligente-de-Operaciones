import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Configuración de tickets
  static Future<Map<String, dynamic>> obtenerConfiguracionTicket() async {
    try {
      final headers = await _headers;
      final response = await http.get(Uri.parse('$baseUrl/configuracion-ticket'), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['configuracion'] ?? {};
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }
  
  static Future<bool> guardarConfiguracionTicket(Map<String, dynamic> config) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/configuracion-ticket'),
        headers: headers,
        body: json.encode(config),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Headers comunes con token de autenticación si está disponible
  static Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> _authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error en el login',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Registro
  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellido,
    required String nombreUsuario,
    required String email,
    required String password,
    String rol = 'user',
  }) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers,
        body: json.encode({
          'nombre': nombre,
          'apellido': apellido,
          'nombre_usuario': nombreUsuario,
          'email': email,
          'password': password,
          'rol': rol,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error en el registro',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Obtener perfil
  static Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _authHeaders(token),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error obteniendo perfil',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> crearSucursal(String token, String nombre, String direccion) async {
    final url = Uri.parse('http://localhost:3000/api/sucursales');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nombre': nombre,
        'direccion': direccion,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> crearRol(String? token, String nombre, String password, int sucursalId, String tipo) async {
    final url = Uri.parse('http://localhost:3000/api/roles');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nombre': nombre,
        'password': password,
        'tipo': tipo,
        'sucursal_id': sucursalId,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> listarSucursales(String? token) async {
    final url = Uri.parse('http://localhost:3000/api/sucursales');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> listarRoles(String? token, int sucursalId) async {
    final url = Uri.parse('http://localhost:3000/api/roles?sucursal_id=$sucursalId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getSucursalesRoles(String? token) async {
    final url = Uri.parse('http://localhost:3000/api/sucursal-rol');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> seleccionarSucursalRol(
    String? token,
    int sucursalId,
    int rolId,
  ) async {
    final url = Uri.parse('http://localhost:3000/api/sucursal-rol/seleccionar');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'sucursal_id': sucursalId,
        'rol_id': rolId,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> autenticarRol(String? token, String nombre, String password, int sucursalId) async {
    final url = Uri.parse('http://localhost:3000/api/roles/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nombre': nombre,
        'password': password,
        'sucursal_id': sucursalId,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<int> obtenerTotalVentas() async {
    try {
      final headers = await _headers;
      final response = await http.get(Uri.parse('$baseUrl/ventas/total'), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['total'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  static Future<Map<String, dynamic>> obtenerResumenVentas() async {
    try {
      final headers = await _headers;
      final response = await http.get(Uri.parse('$baseUrl/ventas/resumen'), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? { 'totalVendidos': 0, 'gananciaBruta': 0, 'gananciaNeta': 0 };
      } else {
        return { 'totalVendidos': 0, 'gananciaBruta': 0, 'gananciaNeta': 0 };
      }
    } catch (e) {
      return { 'totalVendidos': 0, 'gananciaBruta': 0, 'gananciaNeta': 0 };
    }
  }

  static Future<List<dynamic>> obtenerClientes({String? filtro}) async {
    try {
      String url = '$baseUrl/clientes';
      if (filtro != null && filtro.isNotEmpty) {
        url += '?busqueda=${Uri.encodeComponent(filtro)}';
      }
      final headers = await _headers;
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List?) ?? [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> buscarClientePorCiOCelular({String? ciRuc, String? celular, String? token}) async {
    try {
      String url = '$baseUrl/clientes?';
      if (ciRuc != null && ciRuc.isNotEmpty) url += 'busqueda=${Uri.encodeComponent(ciRuc)}';
      if (celular != null && celular.isNotEmpty) url += (url.endsWith('?') ? '' : '&') + 'busqueda=${Uri.encodeComponent(celular)}';
      
      // Usar headers con autenticación si se proporciona token
      Map<String, String> headers = token != null ? _authHeaders(token) : await _headers;
      
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] is List && data['data'].isNotEmpty) {
          return data['data'][0];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> crearCliente({required String ciRuc, required String nombre, required String celular}) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/clientes'),
        headers: headers,
        body: json.encode({
          'ci_ruc': ciRuc,
          'nombre': nombre,
          'celular': celular,
        }),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>> obtenerHistorialComprasCliente(int clienteId) async {
    try {
      final headers = await _headers;
      final response = await http.get(Uri.parse('$baseUrl/clientes/$clienteId/historial'), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List?) ?? [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<bool> editarCliente({required int id, required String nombre, required String celular}) async {
    try {
      final headers = await _headers;
      final response = await http.put(
        Uri.parse('$baseUrl/clientes/$id'),
        headers: headers,
        body: json.encode({'nombre': nombre, 'celular': celular}),
      );
      if (response.statusCode == 200) return true;
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> desactivarCliente(int id) async {
    try {
      final headers = await _headers;
      final response = await http.put(
        Uri.parse('$baseUrl/clientes/$id/desactivar'),
        headers: headers,
      );
      if (response.statusCode == 200) return true;
      return false;
    } catch (e) {
      return false;
    }
  }

  // Productos
  static Future<List<dynamic>> obtenerProductos() async {
    try {
      final headers = await _headers;
      final response = await http.get(Uri.parse('$baseUrl/articulos'), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List?) ?? [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> crearProducto({
    required String nombre,
    required String codigo,
    required double precioCompra,
    required double precioVenta,
    required int cantidad,
    required double iva,
  }) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/articulos'),
        headers: headers,
        body: json.encode({
          'nombre': nombre,
          'codigo': codigo,
          'precio_compra': precioCompra,
          'precio_venta': precioVenta,
          'stock_minimo': cantidad,
          'iva': iva,
        }),
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return data['data'];
      } else if (response.statusCode == 400) {
        // Error de validación del servidor
        throw Exception(data['error'] ?? 'Error de validación');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow; // Re-lanzar excepciones específicas
      }
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>?> actualizarProducto({
    required int id,
    required String nombre,
    required String codigo,
    required double precioCompra,
    required double precioVenta,
    required int cantidad,
    required double iva,
  }) async {
    try {
      final headers = await _headers;
      final response = await http.put(
        Uri.parse('$baseUrl/articulos/$id'),
        headers: headers,
        body: json.encode({
          'nombre': nombre,
          'codigo': codigo,
          'precio_compra': precioCompra,
          'precio_venta': precioVenta,
          'stock_minimo': cantidad,
          'iva': iva,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> eliminarProducto(int id) async {
    try {
      final headers = await _headers;
      final response = await http.delete(
        Uri.parse('$baseUrl/articulos/$id'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===== VENTAS =====
  static Future<List<dynamic>> listarVentas() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/ventas'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Error al obtener ventas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== BENEFICIOS DE CLIENTE PARA VENTA =====
  static Future<Map<String, dynamic>?> verificarBeneficiosCliente(int clienteId) async {
    try {
      // Obtener los headers con el token de autenticación
      final headers = await _headers;
      
      final response = await http.get(
        Uri.parse('$baseUrl/ventas/cliente/$clienteId/beneficios'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else if (response.statusCode == 401) {
        // No autenticado - esto es normal en desarrollo
        print('Info: Endpoint requiere autenticación');
        return null;
      } else {
        throw Exception('Error al verificar beneficios del cliente');
      }
    } catch (e) {
      // Silenciar errores de conexión para no saturar la consola
      print('Info: No se pudo conectar al backend para verificar beneficios');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> crearVenta(Map<String, dynamic> ventaData) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/ventas'),
        headers: headers,
        body: json.encode(ventaData),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al crear venta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== MÉTODOS PARA PRÉSTAMOS =====
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error en GET: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _headers;
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error en PUT: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}