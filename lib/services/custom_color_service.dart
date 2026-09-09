import 'package:flutter/material.dart';

import '../models/nail_color.dart';
import '../library/unified_library_service.dart';

/// «Мои цвета» — прокси к Единой Библиотеке.
/// Все операции автоматически сбрасывают кэш библиотеки, чтобы
/// все экраны сразу видели изменения.
class CustomColorService {
  /// Загрузить все свои цвета
  static Future<List<NailColor>> load() async {
    final all = await UnifiedLibraryService.getAllColors();
    return all.where((c) => c.group == 'my').toList();
  }

  /// Добавить новый цвет + сброс кэша
  static Future<List<NailColor>> add(String name, Color color) =>
      UnifiedLibraryService.addCustomColor(name, color);

  /// Удалить цвет по id + сброс кэша
  static Future<List<NailColor>> delete(String id) =>
      UnifiedLibraryService.deleteCustomColor(id);
}