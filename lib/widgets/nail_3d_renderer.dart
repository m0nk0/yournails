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
    return Container(
      width: width,
      height: height,
      decoration: showNail && design.shadowIntensity > 0
          ? BoxDecoration(
              borderRadius:
                  NailShapeHelper.getBorderRadius(design.shape, width, height),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(design.shadowIntensity * 0.4),
                  blurRadius: 6 * design.shadowIntensity,
                  offset: Offset(0, 3 * design.shadowIntensity),
                ),
              ],
            )
          : null,
      child: Stack(
        children: [
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