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

  // 3D-параметры
  final double edgeDarken;
  final double highlightIntensity;
  final double shadowIntensity;

  // Кутикула (лунка вокруг ногтя)
  final double cuticleWidth;  // 0..1: ширина бороздки
  final double cuticleDepth;  // 0..1: темнее/светлее
  final double cuticleLength; // 0..1: как высоко поднимается к верху ногтя
  final int cuticleTone;      // 0..3: тон кожи
  final Color? cuticleColor;  // цвет кожи клиента с фото (приоритетнее tone)

  // Узор (векторный и PNG-картинка): прозрачность и размер мотива
  final double patternOpacity; // 0..1: 0 = едва видно, 1 = наглухо
  final double patternScale;   // 0.5..2: 1 = исходный размер картинки

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
    this.cuticleWidth = 0.5,
    this.cuticleDepth = 0.5,
    this.cuticleLength = 0.8,
    this.cuticleTone = 1,
    this.cuticleColor,
    this.patternOpacity = 1.0,
    this.patternScale = 1.0,
  });

  bool get hasColor => color != null;
  bool get hasMaterial => material != null;
  bool get hasPattern => patternPath != null && patternPath!.isNotEmpty;
  bool get hasPatternDraw => !pattern.isNone;

  /// Укрывистость слоёв лака: насколько плотно покрытие перекрывает ноготь.
  /// 1 слой → 0.88, 2 слоя → 0.96, 3 слоя → 1.00 (промежуточные значения —
  /// линейная интерполяция).
  ///
  /// РАНЬШЕ было 0.5 / 0.75 / 1.0 — при дефолтных 2 слоях четверть фото
  /// просвечивала сквозь лак, из-за чего возникал эффект «полупрозрачной
  /// пластины». Реальный гель-лак в 2 слоя укрывает ноготь почти полностью.
  double get layerCoverage {
    const double one = 0.88;
    const double two = 0.96;
    const double three = 1.0;
    if (density <= 1.0) return one;
    if (density <= 2.0) return one + (density - 1.0) * (two - one);
    if (density <= 3.0) return two + (density - 2.0) * (three - two);
    return three;
  }

  SelectedDesign copyWith({
    NailColor? color,
    NailMaterial? material,
    NailShape? shape,
    double? density,
    double? brightness,
    NailPattern? pattern,
    String? patternPath,
    String? patternName,
    double? edgeDarken,
    double? highlightIntensity,
    double? shadowIntensity,
    double? cuticleWidth,
    double? cuticleDepth,
    double? cuticleLength,
    int? cuticleTone,
    Color? cuticleColor,
    bool clearCuticleColor = false,
    double? patternOpacity,
    double? patternScale,
  }) {
    return SelectedDesign(
      color: color ?? this.color,
      material: material ?? this.material,
      shape: shape ?? this.shape,
      density: density ?? this.density,
      brightness: brightness ?? this.brightness,
      pattern: pattern ?? this.pattern,
      patternPath: patternPath ?? this.patternPath,
      patternName: patternName ?? this.patternName,
      edgeDarken: edgeDarken ?? this.edgeDarken,
      highlightIntensity: highlightIntensity ?? this.highlightIntensity,
      shadowIntensity: shadowIntensity ?? this.shadowIntensity,
      cuticleWidth: cuticleWidth ?? this.cuticleWidth,
      cuticleDepth: cuticleDepth ?? this.cuticleDepth,
      cuticleLength: cuticleLength ?? this.cuticleLength,
      cuticleTone: cuticleTone ?? this.cuticleTone,
      cuticleColor: clearCuticleColor
          ? null
          : (cuticleColor ?? this.cuticleColor),
      patternOpacity: patternOpacity ?? this.patternOpacity,
      patternScale: patternScale ?? this.patternScale,
    );
  }

  /// Вычисляет итоговый цвет и прозрачность
  DesignRender getRender() {
    if (color == null) {
      return DesignRender(color: Colors.pink, opacity: 1.0);
    }

    final densityFactor = (0.5 + (density - 1.0) * 0.25).clamp(0.5, 1.0);

    // Коэффициент влияния материала и плотности на насыщенность (0..1)
    final saturationFactor =
        ((material?.saturation ?? 1.0) * (0.6 + densityFactor * 0.4)).clamp(0.0, 1.0);

    final hsl = HSLColor.fromColor(color!.color);

    // Насыщенность изменяется ОТНОСИТЕЛЬНО исходной (множитель), а не
    // выставляется абсолютно: иначе серые цвета (насыщенность 0, hue = 0)
    // превращались в бордовый.
    final targetSaturation =
        (hsl.saturation * saturationFactor).clamp(0.0, 1.0);

    final adjustedColor = hsl
        .withSaturation(targetSaturation)
        .withLightness((hsl.lightness * brightness).clamp(0.0, 1.0))
        .toColor();

    // Прозрачность = прозрачность материала × укрывистость слоёв.
    // Шейер-материалы (биогель и т.п.) остаются полупрозрачными,
    // плотные материалы при 2–3 слоях укрывают ноготь почти полностью.
    final opacity =
        ((material?.opacity ?? 1.0) * layerCoverage).clamp(0.15, 1.0);

    return DesignRender(color: adjustedColor, opacity: opacity);
  }
}