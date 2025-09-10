import 'package:flutter/material.dart';
import '../data/educacion_financiera_levels_data.dart';
import '../widgets/educacion_financiera_level_card_widget.dart';
import '../widgets/educacion_financiera_multiple_choice_widget.dart';
import '../widgets/educacion_financiera_true_false_widget.dart';
import '../widgets/educacion_financiera_word_completion_widget.dart';
import '../widgets/educacion_financiera_header_widget.dart';
import '../widgets/educacion_financiera_game_header_widget.dart';
import '../widgets/educacion_financiera_lesson_content_widget.dart';
import '../widgets/educacion_financiera_question_content_widget.dart';
import '../widgets/educacion_financiera_result_dialog_widget.dart';
import '../widgets/educacion_financiera_intro_widget.dart';

import '../services/educacion_financiera_progress_service.dart';
import '../services/educacion_financiera_game_service.dart';

class EducacionFinancieraScreen extends StatefulWidget {
  const EducacionFinancieraScreen({Key? key}) : super(key: key);

  @override
  State<EducacionFinancieraScreen> createState() => _EducacionFinancieraScreenState();
}

class _EducacionFinancieraScreenState extends State<EducacionFinancieraScreen> {
  bool isMobile = false;
  int userLevel = 1;
  int userXP = 0;
  bool showIntro = true; // Nueva variable para controlar la introducción

  bool showGameUI = false;
  bool showQuestion = false;
  int currentStep = 0;
  int trueFalseAnswer = -1;
  int selectedLevelIndex = 0; // Nueva variable para rastrear el nivel seleccionado

  // Usar los datos extraídos del archivo de datos
  List<Map<String, dynamic>> get gameLevels => EducacionFinancieraLevelsData.gameLevels;

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  void _checkScreenSize() {
    setState(() {
      isMobile = MediaQuery.of(context).size.width < 600;
    });
  }

  Future<void> _loadUserProgress() async {
    final progress = await EducacionFinancieraProgressService.loadUserProgress();
    setState(() {
      userLevel = progress['level']!;
      userXP = progress['xp']!;
    });
  }

  Future<void> _saveUserProgress() async {
    await EducacionFinancieraProgressService.saveUserProgress(userLevel, userXP);
  }

  @override
  Widget build(BuildContext context) {
    _checkScreenSize();
    
    if (showGameUI) {
      return _buildGameUI();
    }
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E293B),
              const Color(0xFF0F172A),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return EducacionFinancieraHeaderWidget(
      title: 'Educación Financiera',
      onBackPressed: showIntro ? null : _backToIntro,
      isMobile: isMobile,
    );
  }

  Widget _buildContent() {
    if (showIntro) {
      return EducacionFinancieraIntroWidget(
        onContinue: () => setState(() => showIntro = false),
        isMobile: isMobile,
      );
    }
    
    if (showQuestion) {
      return _buildQuestionContent();
    }
    
    return _buildLevelsGrid();
  }

  Widget _buildLevelsGrid() {
    return Column(
      children: [
        // Header premium compacto
        Container(
          margin: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
                const Color(0xFF0F3460),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F3460).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4A90E2).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF4A90E2).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.school,
                    color: const Color(0xFF4A90E2),
                    size: isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROGRAMA DE EXCELENCIA',
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4A90E2),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Metodologías Interactivas',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCompactGamificationLegend(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Lista de niveles en barras horizontales
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            itemCount: gameLevels.length,
            itemBuilder: (context, index) {
              final level = gameLevels[index];
              final isUnlocked = EducacionFinancieraGameService.isLevelUnlocked(index, userLevel);
              final isCurrentLevel = EducacionFinancieraGameService.isCurrentLevel(index, userLevel);
              
              return Container(
                margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
                child: _buildLevelBar(level, isUnlocked, isCurrentLevel),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactGamificationLegend() {
    return Row(
      children: [
        _buildCompactLegendItem(
          Icons.psychology,
          const Color(0xFF4A90E2),
        ),
        const SizedBox(width: 12),
        _buildCompactLegendItem(
          Icons.auto_fix_high,
          const Color(0xFF00D4AA),
        ),
        const SizedBox(width: 12),
        _buildCompactLegendItem(
          Icons.flash_on,
          const Color(0xFFFFB74D),
        ),
      ],
    );
  }

  Widget _buildCompactLegendItem(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: isMobile ? 14 : 16,
        color: color,
      ),
    );
  }

  Widget _buildLegendItem(String title, IconData icon, Color color, String subtitle) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: isMobile ? 20 : 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isMobile ? 9 : 10,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBar(Map<String, dynamic> level, bool isUnlocked, bool isCurrentLevel) {
    return Container(
      height: isMobile ? 80 : 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isUnlocked
            ? [
                level['color'],
                level['color'].withOpacity(0.8),
                level['color'].withOpacity(0.6),
              ]
            : [
                const Color(0xFF2D3748),
                const Color(0xFF1A202C),
                const Color(0xFF171923),
              ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isUnlocked 
              ? level['color'].withOpacity(0.3) 
              : Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isUnlocked 
            ? level['color'].withOpacity(0.4) 
            : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isUnlocked ? () => _startLevel(level) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Row(
              children: [
                // Badge de nivel
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 10,
                    vertical: isMobile ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: isUnlocked 
                      ? Colors.white.withOpacity(0.2) 
                      : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isUnlocked 
                        ? Colors.white.withOpacity(0.3) 
                        : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${level['level']}',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.w700,
                      color: isUnlocked ? Colors.white : Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Icono
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: isUnlocked 
                      ? Colors.white.withOpacity(0.15) 
                      : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isUnlocked 
                        ? Colors.white.withOpacity(0.25) 
                        : Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    level['icon'],
                    size: isMobile ? 24 : 28,
                    color: isUnlocked ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                // Información del nivel
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        level['title'],
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: isUnlocked ? Colors.white : Colors.grey,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level['subtitle'],
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 13,
                          color: isUnlocked ? Colors.white.withOpacity(0.8) : Colors.grey,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                // Información de gamificación
                _buildGamificationBadge(level, isUnlocked),
                if (isCurrentLevel) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 14,
                      vertical: isMobile ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: isMobile ? 16 : 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CONTINUAR',
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 11,
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

  Widget _buildGamificationBadge(Map<String, dynamic> level, bool isUnlocked) {
    final questionType = level['lesson']['question']['type'];
    String gamificationText = '';
    IconData gamificationIcon = Icons.psychology;
    Color iconColor = const Color(0xFF4A90E2);

    switch (questionType) {
      case 'multiple_choice':
        gamificationText = 'Análisis';
        gamificationIcon = Icons.psychology;
        iconColor = const Color(0xFF4A90E2);
        break;
      case 'word_completion':
        gamificationText = 'Síntesis';
        gamificationIcon = Icons.auto_fix_high;
        iconColor = const Color(0xFF00D4AA);
        break;
      case 'true_false':
        gamificationText = 'Evaluación';
        gamificationIcon = Icons.flash_on;
        iconColor = const Color(0xFFFFB74D);
        break;
      default:
        gamificationText = 'Ejercicio';
        gamificationIcon = Icons.games;
        iconColor = const Color(0xFF9C27B0);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: isUnlocked 
          ? iconColor.withOpacity(0.2) 
          : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked 
            ? iconColor.withOpacity(0.4) 
            : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            gamificationIcon,
            size: isMobile ? 12 : 14,
            color: isUnlocked ? iconColor : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            gamificationText,
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? Colors.white : Colors.grey,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  void _startLevel(Map<String, dynamic> level) {
    // Encontrar el índice del nivel seleccionado
    final levelIndex = gameLevels.indexWhere((l) => l['level'] == level['level']);
    
    setState(() {
      selectedLevelIndex = levelIndex;
      showGameUI = true;
      showQuestion = false; // Resetear para mostrar la lección primero
    });
  }

  Widget _buildGameUI() {
    final currentLevel = gameLevels[selectedLevelIndex];
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              currentLevel['color'],
              currentLevel['color'].withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildGameHeader(currentLevel),
            Expanded(
              child: _buildLessonContent(currentLevel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameHeader(Map<String, dynamic> currentLevel) {
    return EducacionFinancieraGameHeaderWidget(
      currentLevel: currentLevel,
      userLevel: userLevel,
      onBackPressed: _backToLevels,
      isMobile: isMobile,
    );
  }

  Widget _buildLessonContent(Map<String, dynamic> currentLevel) {
    if (showQuestion) {
      return _buildQuestionContent();
    }
    
    return EducacionFinancieraLessonContentWidget(
      currentLevel: currentLevel,
      onStartQuiz: () => setState(() => showQuestion = true),
      isMobile: isMobile,
    );
  }

  Widget _buildQuestionContent() {
    final currentLevel = gameLevels[selectedLevelIndex];
    final question = currentLevel['lesson']['question'];
    
    return EducacionFinancieraQuestionContentWidget(
      question: question,
      questionOptions: _buildQuestionOptions(question),
      isMobile: isMobile,
    );
  }

  Widget _buildQuestionOptions(Map<String, dynamic> question) {
    switch (question['type']) {
      case 'multiple_choice':
        return _buildMultipleChoice(question);
      case 'word_completion':
        return _buildWordCompletion(question);
      case 'true_false':
        return _buildTrueFalse(question);
      default:
        return _buildMultipleChoice(question);
    }
  }

  Widget _buildMultipleChoice(Map<String, dynamic> question) {
    return EducacionFinancieraMultipleChoiceWidget(
      question: question,
      onAnswerSelected: _answerQuestion,
      isMobile: isMobile,
    );
  }

  Widget _buildWordCompletion(Map<String, dynamic> question) {
    return EducacionFinancieraWordCompletionWidget(
      question: question,
      onAnswerSelected: _answerQuestion,
      isMobile: isMobile,
    );
  }

  Widget _buildTrueFalse(Map<String, dynamic> question) {
    return EducacionFinancieraTrueFalseWidget(
      question: question,
      onAnswerSelected: _selectTrueFalse,
      selectedAnswer: trueFalseAnswer,
      isMobile: isMobile,
    );
  }

  void _answerQuestion(int selectedIndex) {
    final currentLevel = gameLevels[userLevel - 1];
    final question = currentLevel['lesson']['question'];
    final isCorrect = EducacionFinancieraGameService.isAnswerCorrect(selectedIndex, question);
    
    if (isCorrect) {
      setState(() {
        userXP += EducacionFinancieraGameService.calculateXPGain(true);
        if (EducacionFinancieraGameService.canAdvanceToNextLevel(userLevel, gameLevels.length)) {
          userLevel = EducacionFinancieraGameService.getNextLevel(userLevel, gameLevels.length);
        }
      });
      _saveUserProgress();
    }
    
    _showResultDialog(isCorrect, question['explanation']);
  }

  void _selectTrueFalse(int statementIndex) {
    setState(() {
      trueFalseAnswer = statementIndex;
    });
    
    // Enviar respuesta automáticamente después de un breve delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _answerQuestion(statementIndex);
    });
  }

  void _showResultDialog(bool isCorrect, String explanation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EducacionFinancieraResultDialogWidget(
        isCorrect: isCorrect,
        explanation: explanation,
        onContinue: () {
          Navigator.of(context).pop();
          _backToLevels();
        },
      ),
    );
  }

  void _backToLevels() {
    setState(() {
      showGameUI = false;
      showQuestion = false;
      trueFalseAnswer = -1;
    });
  }

  void _backToIntro() {
    setState(() {
      showIntro = true;
      showGameUI = false;
      showQuestion = false;
      trueFalseAnswer = -1;
    });
  }
} 