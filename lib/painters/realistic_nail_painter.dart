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

    // Слой 2: C-изгиб
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

    // Слой 5: блик
    if (design.highlightIntensity > 0) {
      final highlight = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..shader = ui.Gradient.linear(
          Offset(0, h / 2),
          Offset(w, h / 2),
          [
            Colors.transparent,
            Colors.white.withOpacity(design.highlightIntensity * 0.4),
            Colors.transparent,
          ],
          [0.3, 0.5, 0.7],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), highlight);
    }

    // Слой 6: глянец
    if (material?.hasGloss ?? false) {
      final gloss = Paint()
        ..shader = ui.Gradient.linear(
          Offset(w / 2, 0),
          Offset(w / 2, h),
          [
            Colors.white.withOpacity(material!.glossIntensity * 0.28),
            Colors.white.withOpacity(material.glossIntensity * 0.08),
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