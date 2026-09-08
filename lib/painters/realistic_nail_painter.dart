import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/selected_design.dart';
import '../models/nail_pattern.dart';
import '../widgets/nail_pattern_layer.dart';
import 'nail_path.dart';
import 'socket_groove.dart';

/// Реалистичный ноготь "как у мастера".
/// Объём строится НЕ чёрными оверлеями (они обесцвечивают лак),
/// а производными цветами самого лака: тёмным и светлым тоном.
///
/// Анатомия (координаты painter'а): НИЗ ногтя = кутикула (скруглён),
/// ВЕРХ = свободный край (торец). Тень валика — внизу, свет ловит торец.
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

    // Интенсивность объёма (ползунок "Объём"), усиленная кривая:
    // даже при дефолтных 0.3 купол хорошо читается
    final e = (design.edgeDarken.clamp(0.0, 1.0) * 1.4).clamp(0.0, 1.0);

    // Производные тона лака: тёмный (изгиб) и светлый (купол/глубина).
    // Затемнение сохраняет hue и saturation — цвет остаётся "вкусным".
    final hsl = HSLColor.fromColor(render.color);
    final dark = hsl
        .withLightness((hsl.lightness * 0.50).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 1.15).clamp(0.0, 1.0))
        .toColor();
    final light = hsl
        .withLightness((hsl.lightness * 1.22 + 0.06).clamp(0.0, 1.0))
        .toColor();

    canvas.save();
    canvas.clipPath(path);

    // Слой 1: базовый цвет
    canvas.drawPath(
      path,
      Paint()..color = render.color.withOpacity(render.opacity),
    );

    // ============ Слой 2: ПОПЕРЕЧНЫЙ КУПОЛ (C-изгиб) ============
    if (e > 0) {
      final a = 0.62 * e; // сила затемнения боков
      final l = 0.42 * e; // сила светлой оси
      final dome = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, h / 2),
          Offset(w, h / 2),
          [
            dark.withOpacity(a),
            dark.withOpacity(a * 0.65),
            Colors.transparent,
            light.withOpacity(l),
            Colors.transparent,
            dark.withOpacity(a * 0.65),
            dark.withOpacity(a),
          ],
          [0.0, 0.14, 0.30, 0.48, 0.66, 0.86, 1.0],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), dome);
    }

    // ============ Слой 3: ПРОДОЛЬНАЯ АРКА (анатомически верная) ============
    // ВНИЗУ (кутикула) — тень кожного валика, нарастает к краю.
    // ВВЕРХУ — тонкая глубина под светлой линией торца, середина светлая.
    if (e > 0) {
      final d = 0.50 * e;
      final arch = Paint()
        ..shader = ui.Gradient.linear(
          Offset(w / 2, 0),
          Offset(w / 2, h),
          [
            dark.withOpacity(d * 0.30),
            Colors.transparent,
            Colors.transparent,
            dark.withOpacity(d * 0.40),
            dark.withOpacity(d * 0.85),
            dark.withOpacity(d),
          ],
          [0.0, 0.14, 0.62, 0.82, 0.94, 1.0],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), arch);
    }

    // ============ Слой 4: ВНУТРЕННЕЕ СВЕЧЕНИЕ (глубина геля) ============
    final glow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w / 2, h * 0.45),
        w * 0.75,
        [
          light.withOpacity(0.05 + 0.10 * e),
          Colors.transparent,
        ],
        [0.35, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glow);

    // Слой 5: паттерн
    if (design.hasPatternDraw) {
      NailPatternPainter(design.pattern).paint(canvas, size);
    }

    // ============ Слой 6: ЖИВОЙ БЛИК ============
    final i = design.highlightIntensity;
    if (i > 0) {
      // Глянец материала управляет бликом: матовый почти не сияет
      final gloss =
          material?.hasGloss == true ? material!.glossIntensity : 0.5;
      final shine = (0.35 + 0.65 * gloss).clamp(0.0, 1.0);

      // Светлота цвета: на тёмных лаках блик меньше и резче,
      // на светлых — шире и мягче
      final lum = render.color.computeLuminance().clamp(0.0, 1.0);

      // (a) Широкая мягкая световая полоса вдоль ногтя.
      //     Blur пропорционален размеру ногтя — без эффекта "шторки".
      canvas.save();
      canvas.translate(w * 0.5, h * 0.45);
      canvas.rotate(-0.16);
      final sheen = Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.09)
        ..shader = ui.Gradient.linear(
          Offset(-w * 0.6, 0),
          Offset(w * 0.6, 0),
          [
            Colors.transparent,
            Colors.white.withOpacity(0.05 * i * shine),
            Colors.white.withOpacity(0.15 * i * shine),
            Colors.white.withOpacity(0.04 * i * shine),
            Colors.transparent,
          ],
          [0.0, 0.28, 0.42, 0.58, 1.0],
        );
      canvas.drawRect(Rect.fromLTRB(-w, -h, w, h), sheen);
      canvas.restore();

      // (b) Зеркальное пятно: мягкое гало + РЕЗКОЕ ядро внутри
      //     (отражение лампы/окна, "мокрый" глянец геля)
      final specR = w * (0.12 + 0.08 * lum);
      canvas.save();
      canvas.translate(w * (0.38 - 0.06 * lum), h * 0.28);
      canvas.rotate(-0.30);
      canvas.scale(1.0, 2.3);

      // гало
      final spec = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..shader = ui.Gradient.radial(
          Offset.zero,
          specR,
          [
            Colors.white.withOpacity(
                (0.55 + 0.25 * (1.0 - lum)) * i * shine),
            Colors.white.withOpacity(0.18 * i * shine),
            Colors.transparent,
          ],
          [0.0, 0.45, 1.0],
        );
      canvas.drawCircle(Offset.zero, specR, spec);

      // резкое ядро
      final core = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2)
        ..shader = ui.Gradient.radial(
          Offset.zero,
          specR * 0.45,
          [
            Colors.white.withOpacity(0.85 * i * shine),
            Colors.white.withOpacity(0.25 * i * shine),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        );
      canvas.drawCircle(Offset.zero, specR * 0.45, core);
      canvas.restore();

      // (c) Светлая кромка ТОРЦА (свободный край, верх ногтя)
      final rim = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, h * 0.20),
          [
            Colors.white.withOpacity(0.30 * i * shine),
            Colors.transparent,
          ],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.22), rim);
    }

    // Слой 7: общий глянец материала (мягкий сверху вниз)
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