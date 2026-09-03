import 'dart:io';
import 'package:flutter/material.dart';
import '../models/selected_design.dart';
import '../models/nail_shape.dart';
import '../painters/nail_path.dart';
import '../painters/realistic_nail_painter.dart';

/// Рендер ногтя: реалистичный painter + PNG-паттерны поверх.
/// Слои можно отключать: showNail / showCuticle.
class Nail3DRenderer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Тень по контуру ногтя (размытый силуэт формы, не прямоугольник!)
          if (showNail && design.shadowIntensity > 0)
            Positioned.fill(
              child: CustomPaint(
                painter: NailShadowPainter(
                  shape: design.shape,
                  intensity: design.shadowIntensity,
                ),
              ),
            ),

          Positioned.fill(
            child: CustomPaint(
              painter: RealisticNailPainter(
                design: design,
                width: width,
                height: height,
                showNail: showNail,
                showCuticle: showCuticle,
              ),
            ),
          ),

          // PNG-паттерн поверх, обрезанный по форме ногтя
          if (showNail && design.hasPattern && design.patternPath != null)
            Positioned.fill(
              child: ClipPath(
                clipper: NailPathClipper(design.shape),
                child: Image.file(
                  File(design.patternPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Тень по контуру ногтя: размытый силуэт формы со смещением вниз
class NailShadowPainter extends CustomPainter {
  final NailShape shape;
  final double intensity;
  const NailShadowPainter({required this.shape, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildNailPath(size.width, size.height, shape);
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