import 'package:flutter/material.dart';

class EducacionFinancieraResultDialogWidget extends StatelessWidget {
  final bool isCorrect;
  final String explanation;
  final VoidCallback onContinue;

  const EducacionFinancieraResultDialogWidget({
    Key? key,
    required this.isCorrect,
    required this.explanation,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.error,
            color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            isCorrect ? '¡Correcto!' : 'Incorrecto',
            style: TextStyle(
              color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(explanation),
      actions: [
        TextButton(
          onPressed: onContinue,
          child: const Text('Continuar'),
        ),
      ],
    );
  }
} 