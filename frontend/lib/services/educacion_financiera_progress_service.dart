import 'package:shared_preferences/shared_preferences.dart';

class EducacionFinancieraProgressService {
  static const String _userLevelKey = 'user_level';
  static const String _userXPKey = 'user_xp';

  /// Cargar el progreso del usuario
  static Future<Map<String, int>> loadUserProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'level': prefs.getInt(_userLevelKey) ?? 1,
      'xp': prefs.getInt(_userXPKey) ?? 0,
    };
  }

  /// Guardar el progreso del usuario
  static Future<void> saveUserProgress(int level, int xp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userLevelKey, level);
    await prefs.setInt(_userXPKey, xp);
  }

  /// Actualizar el nivel del usuario
  static Future<void> updateUserLevel(int newLevel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userLevelKey, newLevel);
  }

  /// Actualizar la experiencia del usuario
  static Future<void> updateUserXP(int newXP) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userXPKey, newXP);
  }

  /// Reiniciar el progreso del usuario
  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userLevelKey);
    await prefs.remove(_userXPKey);
  }

  /// Obtener solo el nivel del usuario
  static Future<int> getUserLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userLevelKey) ?? 1;
  }

  /// Obtener solo la experiencia del usuario
  static Future<int> getUserXP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userXPKey) ?? 0;
  }
} 