import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/selected_design.dart';
import '../models/nail_pattern.dart';
import '../widgets/nail_pattern_layer.dart';
import 'nail_path.dart';
import 'socket_groove.dart';

/// Реалистичный ноготь "как у мастера"
class RealisticNailPainter extends CustomPainter {
  final SelectedDesign design;
  final double width;
  final double height;
  final bool showNail;
  final bool showCuticle;

  const RealisticNailPainter({
    required this.design,
    required this.width,
    required this.height,
    this.showNail = true,
    this.showCuticle = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildNailPath(size.width, size.height, design.shape);

    if (showCuticle) {
      drawSocketGroove(canvas, path, size, design);
    }

    if (!showNail) return;

    final render = design.getRender();
    final material = design.material;
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.clipPath(path);

    // Слой 1: базовый цвет
    canvas.drawPath(
      path,
      Paint()..color = render.color.withOpacity(render.opacity),
    );

    // Слой 2: C-изгиб (затемнение боков)
    if (design.edgeDarken > 0) {
      final cEdge = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, h / 2),
          Offset(w, h / 2),
          [
            Colors.black.withOpacity(design.edgeDarken * 0.35),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(design.edgeDarken * 0.35),
          ],
          [0.0, 0.22, 0.78, 1.0],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), cEdge);
    }

    // Слой 3: радиальный объём
    if (design.edgeDarken > 0) {
      final volume = Paint()
        ..shader = ui.Gradient.radial(
          Offset(w / 2, h / 2),
          w * 0.85,
          [
            Colors.transparent,
            Colors.black.withOpacity(design.edgeDarken * 0.25),
          ],
          [0.55, 1.0],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), volume);
    }

    // Слой 4: паттерн
    if (design.hasPatternDraw) {
      NailPatternPainter(design.pattern).paint(canvas, size);
    }

    // ============ СЛОЙ 5: ЖИВОЙ БЛИК (как на фото мастеров) ============
    final i = design.highlightIntensity;
    if (i > 0) {
      // Глянец материала управляет бликом: матовый почти не сияет
      final gloss =
          material?.hasGloss == true ? material!.glossIntensity : 0.5;
      final shine = (0.35 + 0.65 * gloss).clamp(0.0, 1.0);

      // Светлота цвета: на тёмных лаках блик меньше и резче,
      // на светлых — шире и мягче
      final lum = render.color.computeLuminance().clamp(0.0, 1.0);

      // (a) Широкая мягкая световая полоса вдоль ногтя, слегка наклонная —
      //     отражение C-изгиба (вместо прежней колонны по центру)
      canvas.save();
      canvas.translate(w * 0.5, h * 0.45);
      canvas.rotate(-0.16);
      final sheen = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..shader = ui.Gradient.linear(
          Offset(-w * 0.6, 0),
          Offset(w * 0.6, 0),
          [
            Colors.transparent,
            Colors.white.withOpacity(0.05 * i * shine),
            Colors.white.withOpacity(0.16 * i * shine),
            Colors.white.withOpacity(0.04 * i * shine),
            Colors.transparent,
          ],
          [0.0, 0.28, 0.40, 0.58, 1.0],
        );
      canvas.drawRect(Rect.fromLTRB(-w, -h, w, h), sheen);
      canvas.restore();

      // (b) Зеркальное пятно: яркое вытянутое пятно в верхней трети со
      //     смещением влево — отражение лампы/окна.
      //     Наклон и наклон ногтя дают разную посадку на разных примерках.
      final specR = w * (0.10 + 0.08 * lum);
      canvas.save();
      canvas.translate(w * (0.38 - 0.06 * lum), h * 0.28);
      canvas.rotate(-0.30);
      canvas.scale(1.0, 2.1);
      final spec = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..shader = ui.Gradient.radial(
          Offset.zero,
          specR,
          [
            Colors.white.withOpacity(
                (0.55 + 0.35 * (1.0 - lum)) * i * shine),
            Colors.white.withOpacity(0.18 * i * shine),
            Colors.transparent,
          ],
          [0.0, 0.45, 1.0],
        );
      canvas.drawCircle(Offset.zero, specR, spec);
      canvas.restore();

      // (c) Светлая кромка у торца ногтя — отражение свободного края
      final rim = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
        ..shader = ui.Gradient.linear(
          Offset(0, h),
          Offset(0, h * 0.80),
          [
            Colors.white.withOpacity(0.22 * i * shine),
            Colors.transparent,
          ],
        );
      canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22), rim);
    }

    // Слой 6: общий глянец материала (мягкий сверху вниз)
    if (material?.hasGloss ?? false) {
      final gloss = Paint()
        ..shader = ui.Gradient.linear(
          Offset(w / 2, 0),
          Offset(w / 2, h),
          [
            Colors.white.withOpacity(material!.glossIntensity * 0.18),
            Colors.white.withOpacity(material.glossIntensity * 0.06),
            Colors.transparent,
          ],
          [0.0, 0.3, 0.65],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), gloss);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RealisticNailPainter oldDelegate) {
    return oldDelegate.design != design ||
        oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.showNail != showNail ||
        oldDelegate.showCuticle != showCuticle;
  }
}