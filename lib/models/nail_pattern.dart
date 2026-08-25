import 'package:flutter/material.dart';

/// Типы рисунков (узоров) ногтя
enum NailPatternType {
  none,    // Без рисунка
  french,  // Френч
  ombre,   // Омбре
  stripes, // Полоски (геометрия)
  dots,    // Точки (горошек)
  marble,  // Мрамор
  glitter, // Блёстки
}

/// Рисунок ногтя: тип + цвет узора
class NailPattern {
  final NailPatternType type;
  final Color color;

  const NailPattern({
    this.type = NailPatternType.none,
    this.color = Colors.white,
  });

  bool get isNone => type == NailPatternType.none;

  /// Название типа
  static String getTypeName(NailPatternType type) {
    switch (type) {
      case NailPatternType.none:
        return 'Без рисунка';
      case NailPatternType.french:
        return 'Френч';
      case NailPatternType.ombre:
        return 'Омбре';
      case NailPatternType.stripes:
        return 'Полоски';
      case NailPatternType.dots:
        return 'Точки';
      case NailPatternType.marble:
        return 'Мрамор';
      case NailPatternType.glitter:
        return 'Блёстки';
    }
  }

  /// Иконка типа
  static IconData getTypeIcon(NailPatternType type) {
    switch (type) {
      case NailPatternType.none:
        return Icons.block;
      case NailPatternType.french:
        return Icons.vertical_align_top;
      case NailPatternType.ombre:
        return Icons.gradient;
      case NailPatternType.stripes:
        return Icons.drag_handle;
      case NailPatternType.dots:
        return Icons.grain;
      case NailPatternType.marble:
        return Icons.waves;
      case NailPatternType.glitter:
        return Icons.auto_awesome;
    }
  }
}