import 'package:flutter/material.dart';

/// Модель дизайна ногтей.
/// Для MVP используем цветные заглушки.
/// Позже заменим на реальные PNG из assets/designs/.
class NailDesign {
  final String id;
  final String name;
  final String? imagePath;  // Путь к PNG (для будущих реальных дизайнов)
  final Color color;         // Цвет заглушки (для MVP)
  final String category;

  NailDesign({
    required this.id,
    required this.name,
    this.imagePath,
    required this.color,
    this.category = 'basic',
  });

  /// Есть ли реальный PNG-файл
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
}