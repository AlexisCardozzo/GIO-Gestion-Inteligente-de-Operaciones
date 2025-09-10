import 'package:flutter/material.dart';

class GioColors {
  // Paleta principal inspirada en Treinta
  static const Color primaryDeep = Color(0xFF1E3A8A);    // Azul profundo
  static const Color primaryMedium = Color(0xFF3B82F6);  // Azul medio
  static const Color primaryLight = Color(0xFF60A5FA);   // Azul claro
  static const Color primaryLighter = Color(0xFF93C5FD); // Azul celeste
  static const Color primaryLightest = Color(0xFFDBEAFE); // Azul muy claro

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryDeep,
      primaryMedium,
      primaryLight,
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryLight,
      primaryLighter,
    ],
  );

  // Colores de niveles de fidelidad
  static const Color nivelPlatino = Color(0xFFE5E4E2);
  static const Color nivelOro = Color(0xFFFFD700);
  static const Color nivelPlata = Color(0xFFC0C0C0);
  static const Color nivelBronce = Color(0xFFCD7F32);

  // Colores de estado
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Colores de texto
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Colores de fondo
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundOverlay = Color(0x80000000);

  // Método para obtener color de nivel
  static Color getNivelColor(String nivel) {
    switch (nivel.toUpperCase()) {
      case 'PLATINO':
        return nivelPlatino;
      case 'ORO':
        return nivelOro;
      case 'PLATA':
        return nivelPlata;
      case 'BRONCE':
        return nivelBronce;
      default:
        return nivelBronce;
    }
  }

  // Método para obtener color de texto según nivel
  static Color getNivelTextColor(String nivel) {
    switch (nivel.toUpperCase()) {
      case 'PLATINO':
        return textPrimary;
      case 'ORO':
        return textPrimary;
      case 'PLATA':
        return textPrimary;
      case 'BRONCE':
        return textWhite;
      default:
        return textWhite;
    }
  }
} 