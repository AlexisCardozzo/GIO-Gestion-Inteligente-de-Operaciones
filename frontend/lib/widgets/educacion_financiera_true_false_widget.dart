import 'package:flutter/material.dart';

class EducacionFinancieraTrueFalseWidget extends StatelessWidget {
  final Map<String, dynamic> question;
  final Function(int) onAnswerSelected;
  final int selectedAnswer;
  final bool isMobile;

  const EducacionFinancieraTrueFalseWidget({
    Key? key,
    required this.question,
    required this.onAnswerSelected,
    required this.selectedAnswer,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statements = question['statements'] as List;
    
    return ListView.builder(
      itemCount: statements.length,
      itemBuilder: (context, index) {
        final isSelected = selectedAnswer == index;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onAnswerSelected(index),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 20 : 24),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF10B981).withAlpha((255 * 0.1).round()) : Colors.grey.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF10B981) : Colors.grey.withAlpha((255 * 0.3).round()),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF10B981) : Colors.grey.withAlpha((255 * 0.3).round()),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isSelected ? Icons.check : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                                             child: Text(
                         statements[index],
                         style: TextStyle(
                           fontSize: 18,
                           color: isSelected ? const Color(0xFF10B981) : const Color(0xFF374151),
                           fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                         ),
                       ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}