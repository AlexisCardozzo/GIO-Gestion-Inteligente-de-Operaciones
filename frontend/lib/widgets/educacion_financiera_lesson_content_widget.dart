import 'package:flutter/material.dart';

class EducacionFinancieraLessonContentWidget extends StatelessWidget {
  final Map<String, dynamic> currentLevel;
  final VoidCallback onStartQuiz;
  final bool isMobile;

  const EducacionFinancieraLessonContentWidget({
    Key? key,
    required this.currentLevel,
    required this.onStartQuiz,
    required this.isMobile,
  }) : super(key: key);

  List<TextSpan> _parseContent(String content) {
    List<TextSpan> spans = [];
    List<String> lines = content.split('\n');
    
    for (String line in lines) {
      if (line.trim().isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }
      
      if (line.startsWith('**') && line.endsWith('**')) {
        // Títulos en negrita
        spans.add(TextSpan(
          text: line.substring(2, line.length - 2) + '\n',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF1F2937),
          ),
        ));
      } else if (line.startsWith('•')) {
        // Lista con viñetas
        spans.add(TextSpan(
          text: '  $line\n',
          style: const TextStyle(
            color: Color(0xFF4B5563),
          ),
        ));
      } else if (line.startsWith('❌') || line.startsWith('✅')) {
        // Mitos y realidades
        spans.add(TextSpan(
          text: '$line\n',
          style: const TextStyle(
            color: Color(0xFF4B5563),
          ),
        ));
      } else if (line.startsWith('1.') || line.startsWith('2.') || line.startsWith('3.') || line.startsWith('4.')) {
        // Lista numerada
        spans.add(TextSpan(
          text: '$line\n',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ));
      } else {
        // Texto normal
        spans.add(TextSpan(text: '$line\n'));
      }
    }
    
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 16 : 20),
      padding: EdgeInsets.all(isMobile ? 24 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            currentLevel['lesson']['title'],
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: currentLevel['color'],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
                     Expanded(
             child: SingleChildScrollView(
               child: RichText(
                 text: TextSpan(
                   style: TextStyle(
                     fontSize: isMobile ? 16 : 18,
                     height: 1.6,
                     color: const Color(0xFF374151),
                   ),
                   children: _parseContent(currentLevel['lesson']['content']),
                 ),
               ),
             ),
           ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: isMobile ? 56 : 60,
            child: ElevatedButton(
              onPressed: onStartQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: currentLevel['color'],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: Text(
                'COMENZAR QUIZ',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}