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

/// Выбранный дизайн (цвет + материал + форма + слои + яркость)
class SelectedDesign {
  final NailColor? color;
  final NailMaterial? material;
  final NailShape shape;
  final double density;    // Слои лака (1.0 - 3.0)
  final double brightness; // Яркость (0.7 - 1.3)

  SelectedDesign({
    this.color,
    this.material,
    this.shape = NailShape.oval,
    this.density = 2.0,
    this.brightness = 1.0,
  });

  bool get hasColor => color != null;
  bool get hasMaterial => material != null;

  /// Вычисляет итоговый цвет и прозрачность с учётом всех параметров
  DesignRender getRender() {
    if (color == null) {
      return DesignRender(color: Colors.pink, opacity: 1.0);
    }

    // Плотность: 1 слой = 0.5, 2 слоя = 0.75, 3 слоя = 1.0
    final densityFactor = (0.5 + (density - 1.0) * 0.25).clamp(0.5, 1.0);

    // Насыщенность: материал × плотность (меньше слоёв = бледнее)
    final saturation =
        ((material?.saturation ?? 1.0) * (0.6 + densityFactor * 0.4)).clamp(0.0, 1.0);

    // Цвет с учётом насыщенности и яркости
    final hsl = HSLColor.fromColor(color!.color);
    final adjustedColor = hsl
        .withSaturation(saturation)
        .withLightness((hsl.lightness * brightness).clamp(0.0, 1.0))
        .toColor();

    // Прозрачность: материал × плотность (1 слой = ноготь просвечивает)
    final opacity = ((material?.opacity ?? 1.0) * densityFactor).clamp(0.15, 1.0);

    return DesignRender(color: adjustedColor, opacity: opacity);
  }
}