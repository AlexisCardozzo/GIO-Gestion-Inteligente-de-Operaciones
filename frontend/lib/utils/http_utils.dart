import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class HttpUtils {
  // Método para obtener el token de autenticación
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  
  // Método para obtener los headers de autenticación
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Método para realizar peticiones GET con autenticación
  static Future<http.Response> get(String endpoint) async {
    final token = await getAuthToken();
    return await http.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // Método para realizar peticiones POST con autenticación
  static Future<http.Response> post(String endpoint, dynamic data) async {
    final token = await getAuthToken();
    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
  }

  // Método para realizar peticiones PUT con autenticación
  static Future<http.Response> put(String endpoint, dynamic data) async {
    final token = await getAuthToken();
    return await http.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
  }

  // Método para realizar peticiones DELETE con autenticación
  static Future<http.Response> delete(String endpoint) async {
    final token = await getAuthToken();
    return await http.delete(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}