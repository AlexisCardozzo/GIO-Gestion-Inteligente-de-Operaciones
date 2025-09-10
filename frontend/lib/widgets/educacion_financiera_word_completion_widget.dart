import 'package:flutter/material.dart';

class EducacionFinancieraWordCompletionWidget extends StatelessWidget {
  final Map<String, dynamic> question;
  final Function(int) onAnswerSelected;
  final bool isMobile;

  const EducacionFinancieraWordCompletionWidget({
    Key? key,
    required this.question,
    required this.onAnswerSelected,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final options = question['options'] as List;
    
    return ListView.builder(
      itemCount: options.length,
      itemBuilder: (context, index) {
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
                  color: Colors.grey.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withAlpha((255 * 0.3).round()),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                                             child: Text(
                         options[index],
                         style: const TextStyle(
                           fontSize: 18,
                           color: Color(0xFF374151),
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