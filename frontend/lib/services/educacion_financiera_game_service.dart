import '../data/educacion_financiera_levels_data.dart';

class EducacionFinancieraGameService {
  /// Verificar si una respuesta es correcta
  static bool isAnswerCorrect(int selectedIndex, Map<String, dynamic> question) {
    return selectedIndex == question['correct'];
  }

  /// Calcular la experiencia ganada por respuesta correcta
  static int calculateXPGain(bool isCorrect, {int baseXP = 50}) {
    return isCorrect ? baseXP : 0;
  }

  /// Verificar si el usuario puede avanzar al siguiente nivel
  static bool canAdvanceToNextLevel(int currentLevel, int totalLevels) {
    return currentLevel < totalLevels;
  }

  /// Obtener el siguiente nivel
  static int getNextLevel(int currentLevel, int totalLevels) {
    if (canAdvanceToNextLevel(currentLevel, totalLevels)) {
      return currentLevel + 1;
    }
    return currentLevel;
  }

  /// Verificar si un nivel está desbloqueado
  static bool isLevelUnlocked(int levelIndex, int userLevel) {
    // Permitir acceder a todos los niveles ya completados (incluyendo el actual)
    return levelIndex <= userLevel - 1;
  }

  /// Verificar si es el nivel actual
  static bool isCurrentLevel(int levelIndex, int userLevel) {
    return levelIndex == userLevel - 1;
  }

  /// Obtener el nivel actual del juego
  static Map<String, dynamic>? getCurrentLevel(int userLevel) {
    return EducacionFinancieraLevelsData.getLevel(userLevel);
  }

  /// Obtener el total de niveles disponibles
  static int getTotalLevels() {
    return EducacionFinancieraLevelsData.getTotalLevels();
  }

  /// Verificar si el usuario ha completado todos los niveles
  static bool hasCompletedAllLevels(int userLevel) {
    return userLevel > getTotalLevels();
  }

  /// Obtener el progreso del usuario como porcentaje
  static double getProgressPercentage(int userLevel) {
    final totalLevels = getTotalLevels();
    return (userLevel - 1) / totalLevels;
  }

  /// Obtener el tipo de pregunta de un nivel
  static String getQuestionType(int userLevel) {
    final level = getCurrentLevel(userLevel);
    if (level != null) {
      return level['lesson']['question']['type'] ?? 'multiple_choice';
    }
    return 'multiple_choice';
  }

  /// Verificar si el tipo de pregunta es de verdadero/falso
  static bool isTrueFalseQuestion(int userLevel) {
    return getQuestionType(userLevel) == 'true_false';
  }

  /// Verificar si el tipo de pregunta es de opciones múltiples
  static bool isMultipleChoiceQuestion(int userLevel) {
    return getQuestionType(userLevel) == 'multiple_choice';
  }

  /// Verificar si el tipo de pregunta es de completar palabras
  static bool isWordCompletionQuestion(int userLevel) {
    return getQuestionType(userLevel) == 'word_completion';
  }
} 