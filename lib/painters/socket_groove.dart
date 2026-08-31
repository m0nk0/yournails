import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/selected_design.dart';

/// Тона кожи для бороздки лунки
class CuticleTones {
  static const List<Color> values = [
    Color(0xFFE8C0A8), // светлый
    Color(0xFFD9A982), // пшеничный
    Color(0xFFC08A5E), // смуглый
    Color(0xFF8A5A44), // тёмный
  ];
}

/// Рисует бороздку-лунку вокруг ногтя на заданном Path.
/// Используется и на экране (painter), и в рендере (галерея/клиент).
///
/// [path] — path ногтя в координатах (0,0)-(size.width, size.height)
/// [size] — размер ногтя
void drawSocketGroove(Canvas canvas, Path path, Size size, SelectedDesign design) {
  final widthParam = design.cuticleWidth; // 0..2
  final darkParam = design.cuticleDepth; // 0..1
  final lengthParam = design.cuticleLength; // 0..1
  if (widthParam <= 0.02) return;

  final baseStroke = size.width * widthParam * 0.09;
  final opacity = 0.15 + darkParam * 0.45;

  final tone = CuticleTones.values[design.cuticleTone.clamp(0, 3)];
  final hsl = HSLColor.fromColor(tone);

  final grooveColor = hsl
      .withLightness((hsl.lightness * 0.72).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation * 1.3).clamp(0.0, 1.0))
      .toColor();
  final rimLightColor = hsl
      .withLightness((hsl.lightness * 1.35).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation * 0.85).clamp(0.0, 1.0))
      .toColor();
  final contactColor = hsl
      .withLightness((hsl.lightness * 0.62).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0))
      .toColor();

  final center = Offset(size.width / 2, size.height * 0.85);
  final radius = size.height * (0.35 + 0.65 * lengthParam);

  ui.Shader makeShader(Color color, double maxOp) {
    return ui.Gradient.radial(
      center,
      radius,
      [
        color.withOpacity(maxOp),
        color.withOpacity(maxOp),
        color.withOpacity(0),
      ],
      [0.0, 0.55, 1.0],
    );
  }

  // 1. Мягкий ореол (3 прохода)
  const passes = [
    [1.0, 1.0],
    [1.7, 0.45],
    [2.4, 0.20],
  ];
  for (final p in passes) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseStroke * p[0]
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
      ..shader = makeShader(grooveColor, opacity * p[1]);
    canvas.drawPath(path, paint);
  }

  // 2. Светлый валик снаружи
  final rimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = baseStroke + size.width * 0.10
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
    ..shader = makeShader(rimLightColor, 0.28 + darkParam * 0.15);
  canvas.drawPath(path, rimPaint);

  // 3. Тёмная щель у края ногтя
  final contactPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = size.width * 0.035
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0)
    ..shader = makeShader(contactColor, 0.25 + darkParam * 0.20);
  canvas.drawPath(path, contactPaint);

  // Лёгкая бороздка сверху (при почти полной длине)
  if (lengthParam > 0.85) {
    final topPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseStroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height * 0.15),
        [
          grooveColor.withOpacity(opacity * 0.35),
          grooveColor.withOpacity(0),
        ],
      );
    canvas.drawPath(path, topPaint);
  }
}