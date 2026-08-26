import 'dart:io'; // ИСПРАВЛЕНО: добавлен импорт для File
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
        // Тень под ногтем (drop shadow)
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
            // Слой 1: базовый цвет с opacity
            Positioned.fill(
              child: Opacity(
                opacity: render.opacity,
                child: Container(color: render.color),
              ),
            ),

            // Слой 2: радиальный градиент для объёма (края темнее)
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

            // Слой 3: блик сверху-слева
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

            // Слой 4: рисунок (френч, омбре и т.д.)
            if (design.hasPatternDraw)
              Positioned.fill(
                child: NailPatternLayer(pattern: design.pattern),
              ),

            // Слой 5: PNG-картинка
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

            // Слой 6: глянец материала (если есть)
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