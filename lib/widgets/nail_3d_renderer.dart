import 'dart:io';
import 'package:flutter/material.dart';
import '../models/selected_design.dart';
import '../models/nail_shape.dart';
import 'nail_pattern_layer.dart';

/// Рендер 3D-ногтя с регулируемыми параметрами
class Nail3DRenderer extends StatelessWidget {
  final SelectedDesign design;
  final double width;
  final double height;

  const Nail3DRenderer({
    super.key,
    required this.design,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final render = design.getRender();
    final material = design.material;
    final borderRadius =
        NailShapeHelper.getBorderRadius(design.shape, width, height);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: design.shadowIntensity > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(design.shadowIntensity * 0.5),
                  blurRadius: 8 * design.shadowIntensity,
                  offset: Offset(0, 4 * design.shadowIntensity),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // Слой 1: базовый цвет
            Positioned.fill(
              child: Opacity(
                opacity: render.opacity,
                child: Container(color: render.color),
              ),
            ),

            // Слой 2: радиальный объём (края темнее)
            if (design.edgeDarken > 0)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(design.edgeDarken * 0.4),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),

            // Слой 3: рисунок
            if (design.hasPatternDraw)
              Positioned.fill(
                child: NailPatternLayer(pattern: design.pattern),
              ),

            // Слой 4: PNG-картинка
            if (design.hasPattern)
              Positioned.fill(
                child: Image.file(
                  File(design.patternPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),

            // НОВОЕ Слой 5: C-изгиб (боковые грани темнее)
            if (design.edgeDarken > 0)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(design.edgeDarken * 0.45),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(design.edgeDarken * 0.45),
                      ],
                      stops: const [0.0, 0.25, 0.75, 1.0],
                    ),
                  ),
                ),
              ),

            // НОВОЕ Слой 6: световая колонна (светлая полоса по центру)
            if (design.highlightIntensity > 0)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(design.highlightIntensity * 0.35),
                        Colors.transparent,
                      ],
                      stops: const [0.35, 0.5, 0.65],
                    ),
                  ),
                ),
              ),

            // Слой 7: блик сверху-слева
            if (design.highlightIntensity > 0)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(design.highlightIntensity * 0.4),
                        Colors.white.withOpacity(design.highlightIntensity * 0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.7],
                    ),
                  ),
                ),
              ),

            // Слой 8: глянец материала
            if (material?.hasGloss ?? false)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white
                            .withOpacity((material?.glossIntensity ?? 0.5) * 0.30),
                        Colors.white
                            .withOpacity((material?.glossIntensity ?? 0.5) * 0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.7],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}