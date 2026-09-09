import 'package:flutter/material.dart';

import '../models/nail_color.dart';
import '../library/unified_library_service.dart';

/// «Мои цвета» — прокси к Единой Библиотеке.
/// Все операции автоматически сбрасывают кэш библиотеки.
class CustomColorService {
  /// Загрузить все свои цвета
  static Future<List<NailColor>> load() async {
    final all = await UnifiedLibraryService.getAllColors();
    return all.where((c) => c.group == 'my').toList();
  }

  /// Добавить новый цвет (+ рецепт в description) + сброс кэша
  static Future<List<NailColor>> add(
    String name,
    Color color, {
    String? description,
  }) =>
      UnifiedLibraryService.addCustomColor(
        name,
        color,
        description: description,
      );

  /// Удалить цвет по id + сброс кэша
  static Future<List<NailColor>> delete(String id) =>
      UnifiedLibraryService.deleteCustomColor(id);
}