import 'package:flutter/material.dart';

class OwlLogo extends StatelessWidget {
  final double size;
  final int nivel;
  final double progreso;
  final String mensaje;
  final String emoji;
  
  const OwlLogo({
    Key? key, 
    this.size = 100, 
    this.nivel = 1,
    this.progreso = 0.0,
    this.mensaje = '',
    this.emoji = '🦉',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Búho animado
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: size,
          height: size,
          child: CustomPaint(
            painter: _OwlEvolutionPainter(
              nivel: nivel,
              progreso: progreso,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Emoji del nivel
        Text(
          emoji,
          style: TextStyle(fontSize: size * 0.3),
        ),
        if (mensaje.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            mensaje,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blueAccent,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _OwlEvolutionPainter extends CustomPainter {
  final int nivel;
  final double progreso;
  
  _OwlEvolutionPainter({
    required this.nivel,
    required this.progreso,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha((255 * 0.1).round())
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.88),
        width: size.width * 0.5,
        height: size.height * 0.13,
      ),
      shadowPaint,
    );

    // Dibujar según el nivel
    switch (nivel) {
      case 1:
        _drawEgg(canvas, size, center, progreso);
        break;
      case 2:
        _drawChick(canvas, size, center, progreso);
        break;
      case 3:
        _drawYoungOwl(canvas, size, center, progreso);
        break;
      case 4:
        _drawAdultOwl(canvas, size, center, progreso);
        break;
      case 5:
        _drawLegendaryOwl(canvas, size, center, progreso);
        break;
      default:
        _drawEgg(canvas, size, center, progreso);
    }
  }

  void _drawEgg(Canvas canvas, Size size, Offset center, double progreso) {
    final eggPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final eggBorder = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06;
    
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.55,
        height: size.height * 0.7,
      ),
      eggPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.55,
        height: size.height * 0.7,
      ),
      eggBorder,
    );
    
    // Grieta cuando el progreso es alto
    if (progreso > 0.7) {
      final crack = Path();
      crack.moveTo(center.dx, center.dy - size.height * 0.18);
      crack.lineTo(center.dx - size.width * 0.04, center.dy - size.height * 0.08);
      crack.lineTo(center.dx + size.width * 0.04, center.dy);
      crack.lineTo(center.dx - size.width * 0.04, center.dy + size.height * 0.08);
      crack.lineTo(center.dx, center.dy + size.height * 0.18);
      final crackPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = size.width * 0.025
        ..style = PaintingStyle.stroke;
      canvas.drawPath(crack, crackPaint);
    }
  }

  void _drawChick(Canvas canvas, Size size, Offset center, double progreso) {
    final chickPaint = Paint()
      ..color = Colors.yellow.shade200
      ..style = PaintingStyle.fill;
    
    // Cabeza
    canvas.drawCircle(center, size.width * 0.28, chickPaint);
    
    // Ojos
    final eyeWhitePaint = Paint()..color = Colors.white;
    final eyePupilPaint = Paint()..color = Colors.black;
    final leftEye = center.translate(-size.width * 0.09, -size.height * 0.04);
    final rightEye = center.translate(size.width * 0.09, -size.height * 0.04);
    canvas.drawCircle(leftEye, size.width * 0.06, eyeWhitePaint);
    canvas.drawCircle(rightEye, size.width * 0.06, eyeWhitePaint);
    canvas.drawCircle(leftEye, size.width * 0.03, eyePupilPaint);
    canvas.drawCircle(rightEye, size.width * 0.03, eyePupilPaint);
    
    // Pico
    final beakPaint = Paint()..color = Colors.orange;
    final beak = Path();
    beak.moveTo(center.dx, center.dy + size.height * 0.04);
    beak.lineTo(center.dx - size.width * 0.025, center.dy + size.height * 0.08);
    beak.lineTo(center.dx + size.width * 0.025, center.dy + size.height * 0.08);
    beak.close();
    canvas.drawPath(beak, beakPaint);
  }

  void _drawYoungOwl(Canvas canvas, Size size, Offset center, double progreso) {
    final headPaint = Paint()
      ..color = Colors.lightBlueAccent.shade100
      ..style = PaintingStyle.fill;
    
    // Cabeza
    canvas.drawCircle(center, size.width * 0.28, headPaint);
    
    // Orejas pequeñas
    final earPaint = Paint()..color = Colors.lightBlueAccent.shade200;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-size.width * 0.16, -size.height * 0.18),
        width: size.width * 0.09,
        height: size.height * 0.13,
      ),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(size.width * 0.16, -size.height * 0.18),
        width: size.width * 0.09,
        height: size.height * 0.13,
      ),
      earPaint,
    );
    
    // Ojos
    final eyeWhitePaint = Paint()..color = Colors.white;
    final eyePupilPaint = Paint()..color = Colors.black;
    final leftEye = center.translate(-size.width * 0.09, -size.height * 0.04);
    final rightEye = center.translate(size.width * 0.09, -size.height * 0.04);
    canvas.drawCircle(leftEye, size.width * 0.06, eyeWhitePaint);
    canvas.drawCircle(rightEye, size.width * 0.06, eyeWhitePaint);
    canvas.drawCircle(leftEye, size.width * 0.03, eyePupilPaint);
    canvas.drawCircle(rightEye, size.width * 0.03, eyePupilPaint);
    
    // Pico
    final beakPaint = Paint()..color = Colors.orange;
    final beak = Path();
    beak.moveTo(center.dx, center.dy + size.height * 0.04);
    beak.lineTo(center.dx - size.width * 0.025, center.dy + size.height * 0.08);
    beak.lineTo(center.dx + size.width * 0.025, center.dy + size.height * 0.08);
    beak.close();
    canvas.drawPath(beak, beakPaint);
  }

  void _drawAdultOwl(Canvas canvas, Size size, Offset center, double progreso) {
    final headPaint = Paint()
      ..color = Colors.brown.shade300
      ..style = PaintingStyle.fill;
    
    // Cabeza
    canvas.drawCircle(center, size.width * 0.28, headPaint);
    
    // Orejas grandes
    final earPaint = Paint()..color = Colors.brown.shade400;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-size.width * 0.16, -size.height * 0.18),
        width: size.width * 0.12,
        height: size.height * 0.16,
      ),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(size.width * 0.16, -size.height * 0.18),
        width: size.width * 0.12,
        height: size.height * 0.16,
      ),
      earPaint,
    );
    
    // Ojos grandes
    final eyeWhitePaint = Paint()..color = Colors.white;
    final eyePupilPaint = Paint()..color = Colors.black;
    final leftEye = center.translate(-size.width * 0.09, -size.height * 0.04);
    final rightEye = center.translate(size.width * 0.09, -size.height * 0.04);
    canvas.drawCircle(leftEye, size.width * 0.08, eyeWhitePaint);
    canvas.drawCircle(rightEye, size.width * 0.08, eyeWhitePaint);
    canvas.drawCircle(leftEye, size.width * 0.04, eyePupilPaint);
    canvas.drawCircle(rightEye, size.width * 0.04, eyePupilPaint);
    
    // Pico
    final beakPaint = Paint()..color = Colors.orange;
    final beak = Path();
    beak.moveTo(center.dx, center.dy + size.height * 0.04);
    beak.lineTo(center.dx - size.width * 0.025, center.dy + size.height * 0.08);
    beak.lineTo(center.dx + size.width * 0.025, center.dy + size.height * 0.08);
    beak.close();
    canvas.drawPath(beak, beakPaint);
  }

  void _drawLegendaryOwl(Canvas canvas, Size size, Offset center, double progreso) {
    final headPaint = Paint()
      ..color = Colors.amber.shade300
      ..style = PaintingStyle.fill;
    
    // Cabeza dorada
    canvas.drawCircle(center, size.width * 0.28, headPaint);
    
    // Corona
    final crownPaint = Paint()..color = Colors.yellow.shade600;
    final crown = Path();
    crown.moveTo(center.dx - size.width * 0.2, center.dy - size.height * 0.25);
    crown.lineTo(center.dx - size.width * 0.15, center.dy - size.height * 0.35);
    crown.lineTo(center.dx - size.width * 0.1, center.dy - size.height * 0.25);
    crown.lineTo(center.dx - size.width * 0.05, center.dy - size.height * 0.35);
    crown.lineTo(center.dx, center.dy - size.height * 0.25);
    crown.lineTo(center.dx + size.width * 0.05, center.dy - size.height * 0.35);
    crown.lineTo(center.dx + size.width * 0.1, center.dy - size.height * 0.25);
    crown.lineTo(center.dx + size.width * 0.15, center.dy - size.height * 0.35);
    crown.lineTo(center.dx + size.width * 0.2, center.dy - size.height * 0.25);
    crown.close();
    canvas.drawPath(crown, crownPaint);
    
    // Orejas legendarias
    final earPaint = Paint()..color = Colors.amber.shade400;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-size.width * 0.16, -size.height * 0.18),
        width: size.width * 0.12,
        height: size.height * 0.16,
      ),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(size.width * 0.16, -size.height * 0.18),
        width: size.width * 0.12,
        height: size.height * 0.16,
      ),
      earPaint,
    );
    
    // Ojos brillantes
    final eyeWhitePaint = Paint()..color = Colors.white;
    final eyePupilPaint = Paint()..color = Colors.black;
    final leftEye = center.translate(-size.width * 0.09, -size.height * 0.04);
    final rightEye = center.translate(size.width * 0.09, -size.height * 0.04);
    canvas.drawCircle(leftEye, size.width * 0.08, eyeWhitePaint);
    canvas.drawCircle(rightEye, size.width * 0.08, eyeWhitePaint);
    canvas.drawCircle(leftEye, size.width * 0.04, eyePupilPaint);
    canvas.drawCircle(rightEye, size.width * 0.04, eyePupilPaint);
    
    // Brillo en los ojos
    final sparklePaint = Paint()..color = Colors.yellow.shade300;
    canvas.drawCircle(leftEye.translate(-size.width * 0.02, -size.height * 0.02), 2, sparklePaint);
    canvas.drawCircle(rightEye.translate(-size.width * 0.02, -size.height * 0.02), 2, sparklePaint);
    
    // Pico dorado
    final beakPaint = Paint()..color = Colors.orange.shade600;
    final beak = Path();
    beak.moveTo(center.dx, center.dy + size.height * 0.04);
    beak.lineTo(center.dx - size.width * 0.025, center.dy + size.height * 0.08);
    beak.lineTo(center.dx + size.width * 0.025, center.dy + size.height * 0.08);
    beak.close();
    canvas.drawPath(beak, beakPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}