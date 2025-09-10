import 'package:flutter/material.dart';

class EducacionFinancieraGameHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> currentLevel;
  final int userLevel;
  final VoidCallback? onBackPressed;
  final bool isMobile;

  const EducacionFinancieraGameHeaderWidget({
    Key? key,
    required this.currentLevel,
    required this.userLevel,
    this.onBackPressed,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackPressed,
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentLevel['title'],
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  currentLevel['subtitle'],
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.white.withAlpha((255 * 0.8).round()),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((255 * 0.2).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Nivel $userLevel',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}