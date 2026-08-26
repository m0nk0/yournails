import 'package:flutter/material.dart';
import 'nail_color.dart';
import 'nail_material.dart';
import 'nail_shape.dart';
import 'nail_pattern.dart';

/// Итоговые параметры рендеринга дизайна
class DesignRender {
  final Color color;
  final double opacity;

  DesignRender({required this.color, required this.opacity});
}

/// Выбранный дизайн с 3D-параметрами
class SelectedDesign {
  final NailColor? color;
  final NailMaterial? material;
  final NailShape shape;
  final double density;
  final double brightness;
  final NailPattern pattern;
  final String? patternPath;
  final String? patternName;

  // НОВОЕ: 3D-параметры
  final double edgeDarken;      // 0.0-1.0: затемнение краёв (объём)
  final double highlightIntensity; // 0.0-1.0: блик сверху
  final double shadowIntensity;    // 0.0-1.0: тень под ногтем

  SelectedDesign({
    this.color,
    this.material,
    this.shape = NailShape.oval,
    this.density = 2.0,
    this.brightness = 1.0,
    this.pattern = const NailPattern(),
    this.patternPath,
    this.patternName,
    this.edgeDarken = 0.3,
    this.highlightIntensity = 0.5,
    this.shadowIntensity = 0.4,
  });

  bool get hasColor => color != null;
  bool get hasMaterial => material != null;
  bool get hasPattern => patternPath != null && patternPath!.isNotEmpty;
  bool get hasPatternDraw => !pattern.isNone;

  /// Вычисляет итоговый цвет и прозрачность
  DesignRender getRender() {
    if (color == null) {
      return DesignRender(color: Colors.pink, opacity: 1.0);
    }

    final densityFactor = (0.5 + (density - 1.0) * 0.25).clamp(0.5, 1.0);

    final saturation =
        ((material?.saturation ?? 1.0) * (0.6 + densityFactor * 0.4)).clamp(0.0, 1.0);

    final hsl = HSLColor.fromColor(color!.color);
    final adjustedColor = hsl
        .withSaturation(saturation)
        .withLightness((hsl.lightness * brightness).clamp(0.0, 1.0))
        .toColor();

    final opacity = ((material?.opacity ?? 1.0) * densityFactor).clamp(0.15, 1.0);

    return DesignRender(color: adjustedColor, opacity: opacity);
  }
}