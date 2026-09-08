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
/// ВАЖНО: кожа обнимает ноготь только у кутикулы (низ ногтя).
/// Свободный край (верх) ни с чем не контактирует — там бороздки быть
/// не должно, иначе ноготь выглядит наклейкой с ореолом по контуру.
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

  // Приоритет: кастомный цвет с фото > выбранный тон
  final tone = design.cuticleColor ?? CuticleTones.values[design.cuticleTone.clamp(0, 3)];
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

  // Центр бороздки — у кутикулы (низ ногтя). Радиус НАМНОГО плотнее,
  // чем раньше: эффект гаснет уже к середине ногтя и не достаёт до торца.
  final center = Offset(size.width / 2, size.height * 0.98);
  final radius = size.height * (0.22 + 0.40 * lengthParam);

  ui.Shader makeShader(Color color, double maxOp) {
    return ui.Gradient.radial(
      center,
      radius,
      [
        color.withOpacity(maxOp),
        color.withOpacity(maxOp),
        color.withOpacity(0),
      ],
      [0.0, 0.45, 1.0],
    );
  }

  // 1. Мягкий ореол у кутикулы (3 прохода)
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

  // 2. Светлый валик снаружи — только у кутикулы, ослабленный
  final rimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = baseStroke + size.width * 0.10
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
    ..shader = makeShader(rimLightColor, 0.20 + darkParam * 0.12);
  canvas.drawPath(path, rimPaint);

  // 3. Тёмная щель у края ногтя — только у кутикулы
  final contactPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = size.width * 0.035
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0)
    ..shader = makeShader(contactColor, 0.25 + darkParam * 0.20);
  canvas.drawPath(path, contactPaint);

  // Бороздка сверху (у свободного края) НЕ рисуется:
  // там ноготь не контактирует с кожей.
}