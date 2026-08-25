import 'package:flutter/material.dart';
import 'nail_color.dart';
import 'nail_material.dart';
import 'nail_shape.dart';

/// Итоговые параметры рендеринга дизайна
class DesignRender {
  final Color color;
  final double opacity;

  DesignRender({required this.color, required this.opacity});
}

/// Выбранный дизайн (цвет + материал + форма + слои + яркость + картинка)
class SelectedDesign {
  final NailColor? color;
  final NailMaterial? material;
  final NailShape shape;
  final double density;
  final double brightness;
  final String? patternPath;  // НОВОЕ: путь к PNG-картинке
  final String? patternName;  // НОВОЕ: название картинки

  SelectedDesign({
    this.color,
    this.material,
    this.shape = NailShape.oval,
    this.density = 2.0,
    this.brightness = 1.0,
    this.patternPath,
    this.patternName,
  });

  bool get hasColor => color != null;
  bool get hasMaterial => material != null;
  bool get hasPattern => patternPath != null && patternPath!.isNotEmpty;

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