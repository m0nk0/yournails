import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/nail_pattern.dart';

/// Слой рисунка, рисуется поверх базового цвета
class NailPatternLayer extends StatelessWidget {
  final NailPattern pattern;

  const NailPatternLayer({super.key, required this.pattern});

  @override
  Widget build(BuildContext context) {
    if (pattern.isNone) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: NailPatternPainter(pattern),
      ),
    );
  }
}

/// ПУБЛИЧНЫЙ painter — используется и в виджете, и в canvas-рендере
class NailPatternPainter extends CustomPainter {
  final NailPattern pattern;

  NailPatternPainter(this.pattern);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = pattern.color;

    switch (pattern.type) {
      case NailPatternType.none:
        break;
      case NailPatternType.french:
        _drawFrench(canvas, size, paint);
        break;
      case NailPatternType.ombre:
        _drawOmbre(canvas, size, paint);
        break;
      case NailPatternType.stripes:
        _drawStripes(canvas, size, paint);
        break;
      case NailPatternType.dots:
        _drawDots(canvas, size, paint);
        break;
      case NailPatternType.marble:
        _drawMarble(canvas, size, paint);
        break;
      case NailPatternType.glitter:
        _drawGlitter(canvas, size, paint);
        break;
    }
  }

  void _drawFrench(Canvas canvas, Size size, Paint paint) {
    final tipH = size.height * 0.28;
    final smileD = size.height * 0.12;

    final rect = Path()..addRect(Rect.fromLTWH(0, 0, size.width, tipH));
    final smile = Path()
      ..addOval(Rect.fromLTWH(
        -size.width * 0.1,
        tipH - smileD,
        size.width * 1.2,
        smileD * 2,
      ));

    canvas.drawPath(
      Path.combine(PathOperation.difference, rect, smile),
      paint,
    );
  }

  void _drawOmbre(Canvas canvas, Size size, Paint paint) {
    paint.shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        pattern.color.withOpacity(0.0),
        pattern.color.withOpacity(0.9),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawStripes(Canvas canvas, Size size, Paint paint) {
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06;

    final gap = size.width * 0.25;
    for (double x = -size.height; x < size.width + size.height; x += gap) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height * 0.6, 0);
      canvas.drawPath(path, paint);
    }
  }

  void _drawDots(Canvas canvas, Size size, Paint paint) {
    final r = size.width * 0.06;
    const cols = 4;
    const rows = 5;

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        final dx = size.width * (i + 0.5) / cols +
            (j.isOdd ? size.width * 0.08 : 0);
        final dy = size.height * (j + 0.5) / rows;
        canvas.drawCircle(Offset(dx, dy), r, paint);
      }
    }
  }

  void _drawMarble(Canvas canvas, Size size, Paint paint) {
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02;

    final rnd = math.Random(7);
    for (int i = 0; i < 4; i++) {
      final path = Path();
      double x = size.width * (0.15 + 0.22 * i);
      path.moveTo(x, 0);

      for (double y = 0; y <= size.height; y += size.height / 6) {
        x += (rnd.nextDouble() - 0.5) * size.width * 0.25;
        x = x.clamp(0, size.width);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint..color = pattern.color.withOpacity(0.7));
    }
  }

  void _drawGlitter(Canvas canvas, Size size, Paint paint) {
    final rnd = math.Random(42);

    for (int i = 0; i < 60; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = 0.5 + rnd.nextDouble() * size.width * 0.02;

      canvas.drawCircle(
        Offset(dx, dy),
        r,
        paint..color = pattern.color.withOpacity(0.4 + rnd.nextDouble() * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant NailPatternPainter oldDelegate) =>
      oldDelegate.pattern.type != pattern.type ||
      oldDelegate.pattern.color != pattern.color;
}