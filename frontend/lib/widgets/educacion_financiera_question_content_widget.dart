import 'package:flutter/material.dart';

class EducacionFinancieraQuestionContentWidget extends StatelessWidget {
  final Map<String, dynamic> question;
  final Widget questionOptions;
  final bool isMobile;

  const EducacionFinancieraQuestionContentWidget({
    Key? key,
    required this.question,
    required this.questionOptions,
    required this.isMobile,
  }) : super(key: key);

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
            question['text'],
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: questionOptions,
          ),
        ],
      ),
    );
  }
}