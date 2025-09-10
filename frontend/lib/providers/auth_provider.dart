import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  int? _sucursalIdActivo;
  String? _nombreSucursalActivo;
  int? _rolIdActivo;
  String? _nombreRolActivo;
  String? _tipoRolActivo;

  // Getters
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;
  bool get hasActiveSucursalAndRol => _sucursalIdActivo != null && _rolIdActivo != null;
  bool get needsSelection => isAuthenticated && !hasActiveSucursalAndRol;
  int? get userId => _user?.id;
  int? get sucursalIdActivo => _sucursalIdActivo;
  String? get nombreSucursalActivo => _nombreSucursalActivo;
  int? get rolIdActivo => _rolIdActivo;
  String? get nombreRolActivo => _nombreRolActivo;
  String? get tipoRolActivo => _tipoRolActivo;

  // Constructor - cargar token guardado
  AuthProvider() {
    _loadToken();
  }

  // Cargar token desde SharedPreferences
  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      if (savedToken != null) {
        _token = savedToken;
        notifyListeners();
      }
    } catch (e) {
      print('Error cargando token: $e');
    }
  }

  // Guardar token en SharedPreferences
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      print('Error guardando token: $e');
    }
  }

  // Eliminar token de SharedPreferences
  Future<void> _clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      print('Error eliminando token: $e');
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.login(email, password);
      
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        _token = data['token']?.toString();
        if (_token != null) {
          await _saveToken(_token!);
        }
        if (data['user'] != null) {
          _user = User.fromJson(data['user']);
        }
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['error']?.toString() ?? 'Error en el login');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: $e');
      _setLoading(false);
      return false;
    }
  }

  // Registro
  Future<bool> register({
    required String nombre,
    required String apellido,
    required String nombreUsuario,
    required String email,
    required String password,
    String rol = 'user',
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.register(
        nombre: nombre,
        apellido: apellido,
        nombreUsuario: nombreUsuario,
        email: email,
        password: password,
        rol: rol,
      );
      
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        _token = data['token']?.toString();
        if (_token != null) {
          await _saveToken(_token!);
        }
        if (data['user'] != null) {
          _user = User.fromJson(data['user']);
        }
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['error']?.toString() ?? 'Error en el registro');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: $e');
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _user = null;
    _token = null;
    await _clearToken();
    _clearError();
    // Asegurarnos de limpiar la información de sucursal y rol
    _sucursalIdActivo = null;
    _nombreSucursalActivo = null;
    _rolIdActivo = null;
    _nombreRolActivo = null;
    _tipoRolActivo = null;
    notifyListeners();
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void setSucursalActiva(int id, String nombre) {
    _sucursalIdActivo = id;
    _nombreSucursalActivo = nombre;
    notifyListeners();
  }

  void setRolActivo(int id, String nombre, [String tipo = 'Vendedor']) {
    _rolIdActivo = id;
    _nombreRolActivo = nombre;
    _tipoRolActivo = tipo;
    notifyListeners();
  }

  void limpiarSucursalYRol() {
    _sucursalIdActivo = null;
    _nombreSucursalActivo = null;
    _rolIdActivo = null;
    _nombreRolActivo = null;
    _tipoRolActivo = null;
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _saveToken(token);
    notifyListeners();
  }
}