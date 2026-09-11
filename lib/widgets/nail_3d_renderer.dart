import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/selected_design.dart';
import '../models/nail_shape.dart';
import '../painters/nail_path.dart';
import '../painters/realistic_nail_painter.dart';

/// Рендер ногтя: реалистичный painter, PNG-узор встроен ВНУТРЬ него
/// (рисуется под бликами и глянцем — как принт под топом).
/// Больше никакого верхнего оверлея, убивающего 3D.
/// Слои можно отключать: showNail / showCuticle.
class Nail3DRenderer extends StatefulWidget {
  final SelectedDesign design;
  final double width;
  final double height;
  final bool showNail;
  final bool showCuticle;

  const Nail3DRenderer({
    super.key,
    required this.design,
    required this.width,
    required this.height,
    this.showNail = true,
    this.showCuticle = true,
  });

  @override
  State<Nail3DRenderer> createState() => _Nail3DRendererState();
}

class _Nail3DRendererState extends State<Nail3DRenderer> {
  ui.Image? _patternImage;
  String? _loadedPath;

  @override
  void initState() {
    super.initState();
    _loadPattern();
  }

  @override
  void didUpdateWidget(covariant Nail3DRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.design.patternPath != widget.design.patternPath) {
      _loadPattern();
    }
  }

  @override
  void dispose() {
    _patternImage?.dispose();
    super.dispose();
  }

  Future<void> _loadPattern() async {
    final path = widget.design.patternPath;

    // Узора нет — сбрасываем картинку
    if (path == null || !widget.design.hasPattern) {
      if (_patternImage != null || _loadedPath != null) {
        setState(() {
          _patternImage?.dispose();
          _patternImage = null;
          _loadedPath = null;
        });
      }
      return;
    }

    // Уже загружено именно это фото — не передекодируем
    if (path == _loadedPath) return;

    try {
      final file = File(path);
      if (!await file.exists()) return;
      final bytes = await file.readAsBytes();
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (i) => completer.complete(i));
      final img = await completer.future;
      if (!mounted) return;
      setState(() {
        _patternImage?.dispose();
        _patternImage = img;
        _loadedPath = path;
      });
    } catch (_) {
      // Файл узора недоступен — рисуем без него, без краха
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          // Тень по контуру ногтя (амбиент + направленная)
          if (widget.showNail && widget.design.shadowIntensity > 0)
            Positioned.fill(
              child: CustomPaint(
                painter: NailShadowPainter(
                  shape: widget.design.shape,
                  intensity: widget.design.shadowIntensity,
                ),
              ),
            ),

          // Ноготь со всеми слоями; PNG-узор передаётся ВНУТРЬ painter
          Positioned.fill(
            child: CustomPaint(
              painter: RealisticNailPainter(
                design: widget.design,
                width: widget.width,
                height: widget.height,
                showNail: widget.showNail,
                showCuticle: widget.showCuticle,
                patternImage: _patternImage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Тень по контуру ногтя:
/// 1) амбиент — тонкая размытая тень ВОКРУГ всего контура (ноготь
///    «вдавлен» в палец, уходит эффект наклейки);
/// 2) направленная — смещённый вниз силуэт (объём над кожей).
class NailShadowPainter extends CustomPainter {
  final NailShape shape;
  final double intensity;
  const NailShadowPainter({
    required this.shape,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildNailPath(size.width, size.height, shape);

    // 1) Амбиент-тень: stroke по контуру, половина внутрь (скроется
    //    под ногтем), половина наружу = мягкий контактный ореол
    canvas.save();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + 5 * intensity
        ..color = Colors.black.withOpacity(intensity * 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + 4 * intensity),
    );
    canvas.restore();

    // 2) Направленная тень снизу (как было)
    canvas.save();
    canvas.translate(0, 3 * intensity);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(intensity * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * intensity),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant NailShadowPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.intensity != intensity;
}

/// Обрезает PNG по форме ногтя
class NailPathClipper extends CustomClipper<Path> {
  final NailShape shape;
  const NailPathClipper(this.shape);

  @override
  Path getClip(Size size) => buildNailPath(size.width, size.height, shape);

  @override
  bool shouldReclip(covariant NailPathClipper oldClipper) =>
      oldClipper.shape != shape;
}