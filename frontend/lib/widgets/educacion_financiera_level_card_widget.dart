import 'package:flutter/material.dart';

class EducacionFinancieraLevelCardWidget extends StatelessWidget {
  final Map<String, dynamic> level;
  final bool isUnlocked;
  final bool isCurrentLevel;
  final VoidCallback? onTap;
  final bool isMobile;

  const EducacionFinancieraLevelCardWidget({
    Key? key,
    required this.level,
    required this.isUnlocked,
    required this.isCurrentLevel,
    required this.onTap,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUnlocked
            ? [
                level['color'],
                level['color'].withAlpha((255 * 0.7).round()),
                level['color'].withAlpha((255 * 0.5).round()),
              ]
            : [
                const Color(0xFF2D3748),
                const Color(0xFF1A202C),
                const Color(0xFF171923),
              ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isUnlocked 
              ? level['color'].withAlpha((255 * 0.4).round()) 
              : Colors.black.withAlpha((255 * 0.3).round()),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isUnlocked 
            ? level['color'].withAlpha((255 * 0.3).round()) 
            : Colors.grey.withAlpha((255 * 0.2).round()),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Badge de nivel
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 10,
                    vertical: isMobile ? 4 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: isUnlocked 
                      ? Colors.white.withAlpha((255 * 0.2).round()) 
                      : Colors.grey.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUnlocked 
                        ? Colors.white.withAlpha((255 * 0.3).round()) 
                        : Colors.grey.withAlpha((255 * 0.3).round()),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'NIVEL ${level['level']}',
                    style: TextStyle(
                      fontSize: isMobile ? 8 : 9,
                      fontWeight: FontWeight.w700,
                      color: isUnlocked ? Colors.white : Colors.grey,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Icono principal
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: isUnlocked 
                      ? Colors.white.withAlpha((255 * 0.1).round()) 
                      : Colors.grey.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isUnlocked 
                        ? Colors.white.withAlpha((255 * 0.2).round()) 
                        : Colors.grey.withAlpha((255 * 0.2).round()),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    level['icon'],
                    size: isMobile ? 28 : 32,
                    color: isUnlocked ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                // Título del nivel
                Text(
                  level['title'],
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? Colors.white : Colors.grey,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Subtítulo
                Text(
                  level['subtitle'],
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    color: isUnlocked ? Colors.white.withAlpha((255 * 0.8).round()) : Colors.grey,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                  const SizedBox(height: 12),
                  _buildGamificationInfo(),
                if (isCurrentLevel) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 14,
                      vertical: isMobile ? 6 : 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withAlpha((255 * 0.2).round()),
                          Colors.white.withAlpha((255 * 0.1).round()),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withAlpha((255 * 0.3).round()),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: isMobile ? 12 : 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CONTINUAR',
                          style: TextStyle(
                            fontSize: isMobile ? 9 : 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGamificationInfo() {
    final questionType = level['lesson']['question']['type'];
    String gamificationText = '';
    String gamificationSubtitle = '';
    IconData gamificationIcon = Icons.psychology;
    Color iconColor = const Color(0xFF4A90E2);

    switch (questionType) {
      case 'multiple_choice':
        gamificationText = 'Análisis Crítico';
        gamificationSubtitle = 'Opción Múltiple';
        gamificationIcon = Icons.psychology;
        iconColor = const Color(0xFF4A90E2);
        break;
      case 'word_completion':
        gamificationText = 'Síntesis Conceptual';
        gamificationSubtitle = 'Completar Palabras';
        gamificationIcon = Icons.auto_fix_high;
        iconColor = const Color(0xFF00D4AA);
        break;
      case 'true_false':
        gamificationText = 'Evaluación Rápida';
        gamificationSubtitle = 'Verdadero/Falso';
        gamificationIcon = Icons.flash_on;
        iconColor = const Color(0xFFFFB74D);
        break;
      default:
        gamificationText = 'Ejercicio Interactivo';
        gamificationSubtitle = 'Gamificación';
        gamificationIcon = Icons.games;
        iconColor = const Color(0xFF9C27B0);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: isUnlocked 
          ? iconColor.withAlpha((255 * 0.15).round()) 
          : Colors.grey.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked 
            ? iconColor.withAlpha((255 * 0.3).round()) 
            : Colors.grey.withAlpha((255 * 0.2).round()),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            gamificationIcon,
            size: isMobile ? 12 : 14,
            color: isUnlocked ? iconColor : Colors.grey,
          ),
          const SizedBox(height: 2),
          Text(
            gamificationText,
            style: TextStyle(
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? Colors.white : Colors.grey,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Text(
            gamificationSubtitle,
            style: TextStyle(
              fontSize: isMobile ? 6 : 7,
              fontWeight: FontWeight.w400,
              color: isUnlocked ? Colors.white.withOpacity(0.7) : Colors.grey,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}