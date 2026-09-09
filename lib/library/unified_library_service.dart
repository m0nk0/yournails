import 'package:flutter/material.dart';

import '../models/nail_color.dart';
import '../models/nail_material.dart';
import '../models/nail_pattern.dart';
import '../services/library_service.dart';
import '../services/custom_color_service.dart';
import '../services/design_sets_service.dart';
import '../services/trend_palettes_service.dart';
import 'builtin_library_service.dart';
import 'design_library.dart';

/// Единый сервис библиотеки.
/// Объединяет встроенные данные (60 цветов, 5 материалов, 7 паттернов)
/// с пользовательскими данными из ОБОИХ источников «Моих цветов»:
///  - LibraryService (library.json) — основной источник
///  - CustomColorService (custom_colors.json) — LEGACY-мост, пока миксер
///    не переведён на LibraryService (шаг 2.4)
class UnifiedLibraryService {
  static DesignLibrary? _unifiedLibrary;

  /// Получить полную библиотеку: встроенные + пользовательские данные.
  /// Кэшируется. При изменении пользовательских данных вызывать [invalidateCache].
  static Future<DesignLibrary> getFullLibrary() async {
    if (_unifiedLibrary != null) {
      return _unifiedLibrary!;
    }

    // Загружаем встроенную библиотеку
    final builtin = await BuiltinLibraryService.getLibrary();

    // Пользовательские цвета: основной источник + legacy-мост (без дублей)
    final libraryCustom = await LibraryService.getCustomColors();
    final seen = <String>{for (final c in libraryCustom) c.id};
    final customColors = [...libraryCustom];
    try {
      final legacyCustom = await CustomColorService.load();
      for (final c in legacyCustom) {
        if (seen.contains(c.id)) continue;
        customColors.add(NailColor(
          id: c.id,
          name: c.name,
          color: c.color,
          group: 'my',
        ));
      }
    } catch (_) {}

    final customMaterials = await LibraryService.getCustomMaterials();

    // Объединяем
    final allColors = [...builtin.colors, ...customColors];
    final allMaterials = [...builtin.materials, ...customMaterials];
    final allPatterns = [...builtin.patterns];

    final unifiedManifest = builtin.manifest.copyWith(
      colorCount: allColors.length,
      materialCount: allMaterials.length,
      patternCount: allPatterns.length,
    );

    _unifiedLibrary = DesignLibrary(
      manifest: unifiedManifest,
      colors: allColors,
      materials: allMaterials,
      patterns: allPatterns,
    );

    return _unifiedLibrary!;
  }

  // ============ СИНХРОННЫЕ РЕЗОЛВЕРЫ (с поддержкой старых ID) ============

  /// Найти цвет по ID: новая библиотека → старая классика → трендовые палитры.
  static NailColor? resolveColor(String? id) {
    if (id == null) return null;

    final cached = _unifiedLibrary?.colors;
    if (cached != null) {
      for (final c in cached) {
        if (c.id == id) return c;
      }
    }

    for (final c in DesignSetsService.getColors()) {
      if (c.id == id) return c;
    }

    for (final p in TrendPalettesService.getPalettes()) {
      for (final c in p.colors) {
        if (c.id == id) return c;
      }
    }

    return null;
  }

  /// Найти материал по ID: новая библиотека → старые материалы.
  static NailMaterial? resolveMaterial(String? id) {
    if (id == null) return null;

    final cached = _unifiedLibrary?.materials;
    if (cached != null) {
      for (final m in cached) {
        if (m.id == id) return m;
      }
    }

    for (final m in DesignSetsService.getMaterials()) {
      if (m.id == id) return m;
    }

    return null;
  }

  // ============ ОПЕРАЦИИ С ПОЛЬЗОВАТЕЛЬСКИМИ ДАННЫМИ ============

  /// Удалить пользовательский цвет из любого источника + сброс кэша
  static Future<void> deleteCustomColor(String id) async {
    await LibraryService.deleteCustomColor(id);
    try {
      await CustomColorService.delete(id);
    } catch (_) {}
    invalidateCache();
  }

  /// Добавить пользовательский цвет (основной источник) + сброс кэша.
  /// На шаге 2.4 миксер будет вызывать именно этот метод.
  static Future<void> addCustomColor(String name, Color color) async {
    await LibraryService.addCustomColor(name, color);
    invalidateCache();
  }

  // ============ АСИНХРОННЫЙ API ============

  /// Получить все цвета (встроенные + пользовательские)
  static Future<List<NailColor>> getAllColors() async {
    final library = await getFullLibrary();
    return library.colors;
  }

  /// Получить все материалы (встроенные + пользовательские)
  static Future<List<NailMaterial>> getAllMaterials() async {
    final library = await getFullLibrary();
    return library.materials;
  }

  /// Получить все паттерны
  static Future<List<NailPattern>> getAllPatterns() async {
    final library = await getFullLibrary();
    return library.patterns;
  }

  /// Получить цвета по группе
  static Future<List<NailColor>> getColorsByGroup(String group) async {
    final library = await getFullLibrary();
    return library.getColorsByGroup(group);
  }

  /// Получить все доступные группы цветов
  static Future<List<String>> getAvailableColorGroups() async {
    final library = await getFullLibrary();
    return library.getAvailableColorGroups();
  }

  /// Найти цвет по ID (ищет во встроенных, пользовательских и legacy)
  static Future<NailColor?> findColorById(String id) async {
    await getFullLibrary();
    return resolveColor(id);
  }

  /// Найти материал по ID
  static Future<NailMaterial?> findMaterialById(String id) async {
    await getFullLibrary();
    return resolveMaterial(id);
  }

  /// Сброс кэша. Вызывать после изменения пользовательских данных.
  static void invalidateCache() {
    _unifiedLibrary = null;
  }

  /// Полная перезагрузка: сброс кэша + повторная загрузка
  static Future<DesignLibrary> reload() async {
    invalidateCache();
    return getFullLibrary();
  }
}