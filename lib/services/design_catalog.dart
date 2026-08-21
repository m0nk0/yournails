import 'package:flutter/material.dart';
import '../models/nail_design.dart';

/// Каталог дизайнов ногтей.
/// Для MVP — захардкоженный список с цветными заглушками.
/// Позже заменим на загрузку из assets/designs/.
class DesignCatalog {
  static List<NailDesign> getAll() {
    return [
      NailDesign(
        id: 'design_1',
        name: 'Классический красный',
        color: const Color(0xFFE53935),
        category: 'classic',
      ),
      NailDesign(
        id: 'design_2',
        name: 'Нежный розовый',
        color: const Color(0xFFF8BBD0),
        category: 'classic',
      ),
      NailDesign(
        id: 'design_3',
        name: 'Френч белый',
        color: const Color(0xFFF5F5F5),
        category: 'french',
      ),
      NailDesign(
        id: 'design_4',
        name: 'Глубокий синий',
        color: const Color(0xFF1E88E5),
        category: 'classic',
      ),
      NailDesign(
        id: 'design_5',
        name: 'Золотой',
        color: const Color(0xFFFFD700),
        category: 'glamour',
      ),
      NailDesign(
        id: 'design_6',
        name: 'Черный глянец',
        color: const Color(0xFF212121),
        category: 'classic',
      ),
      NailDesign(
        id: 'design_7',
        name: 'Мятный',
        color: const Color(0xFF80CBC4),
        category: 'summer',
      ),
      NailDesign(
        id: 'design_8',
        name: 'Лавандовый',
        color: const Color(0xFFB39DDB),
        category: 'summer',
      ),
    ];
  }

  /// Получить дизайны по категории
  static List<NailDesign> getByCategory(String category) {
    return getAll().where((d) => d.category == category).toList();
  }
}