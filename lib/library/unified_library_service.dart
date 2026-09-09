import 'package:flutter/material.dart';

import '../models/nail_color.dart';
import '../models/nail_material.dart';
import '../models/nail_pattern.dart';
import '../services/library_service.dart';
import '../services/trend_palettes_service.dart';
import 'builtin_library_service.dart';
import 'design_library.dart';
import 'legacy_catalog.dart';

/// Единый сервис библиотеки.
/// Объединяет встроенные данные (60 цветов, 5 материалов, 7 паттернов)
/// с пользовательскими данными из LibraryService (library.json).
class UnifiedLibraryService {
  static DesignLibrary? _unifiedLibrary;

  /// Получить полную библиотеку: встроенные + пользовательские данные.
  static Future<DesignLibrary> getFullLibrary() async {
    if (_unifiedLibrary != null) {
      return _unifiedLibrary!;
    }

    final builtin = await BuiltinLibraryService.getLibrary();
    final customColors = await LibraryService.getCustomColors();
    final customMaterials = await LibraryService.getCustomMaterials();

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

  // ============ СИНХРОННЫЕ РЕЗОЛВЕРЫ ============

  /// Найти цвет по ID: новая библиотека → архив старых ID → тренды.
  static NailColor? resolveColor(String? id) {
    if (id == null) return null;

    final cached = _unifiedLibrary?.colors;
    if (cached != null) {
      for (final c in cached) {
        if (c.id == id) return c;
      }
    }

    for (final c in LegacyCatalog.colors) {
      if (c.id == id) return c;
    }

    for (final p in TrendPalettesService.getPalettes()) {
      for (final c in p.colors) {
        if (c.id == id) return c;
      }
    }

    return null;
  }

  /// Найти материал по ID: новая библиотека → архив старых ID.
  static NailMaterial? resolveMaterial(String? id) {
    if (id == null) return null;

    final cached = _unifiedLibrary?.materials;
    if (cached != null) {
      for (final m in cached) {
        if (m.id == id) return m;
      }
    }

    for (final m in LegacyCatalog.materials) {
      if (m.id == id) return m;
    }

    return null;
  }

  // ============ ОПЕРАЦИИ С ПОЛЬЗОВАТЕЛЬСКИМИ ДАННЫМИ ============

  /// Добавить пользовательский цвет (+ рецепт в description) + сброс кэша.
  static Future<List<NailColor>> addCustomColor(
    String name,
    Color color, {
    String? description,
  }) async {
    final result = await LibraryService.addCustomColor(
      name,
      color,
      description: description,
    );
    invalidateCache();
    return result;
  }

  /// Удалить пользовательский цвет + сброс кэша.
  static Future<List<NailColor>> deleteCustomColor(String id) async {
    final result = await LibraryService.deleteCustomColor(id);
    invalidateCache();
    return result;
  }

  /// Добавить пользовательский материал + сброс кэша.
  static Future<void> addCustomMaterial(NailMaterial m) async {
    await LibraryService.addCustomMaterial(m);
    invalidateCache();
  }

  /// Удалить пользовательский материал + сброс кэша.
  static Future<void> deleteCustomMaterial(String id) async {
    await LibraryService.deleteCustomMaterial(id);
    invalidateCache();
  }

  // ============ АСИНХРОННЫЙ API ============

  static Future<List<NailColor>> getAllColors() async {
    final library = await getFullLibrary();
    return library.colors;
  }

  static Future<List<NailMaterial>> getAllMaterials() async {
    final library = await getFullLibrary();
    return library.materials;
  }

  static Future<List<NailPattern>> getAllPatterns() async {
    final library = await getFullLibrary();
    return library.patterns;
  }

  static Future<List<NailColor>> getColorsByGroup(String group) async {
    final library = await getFullLibrary();
    return library.getColorsByGroup(group);
  }

  static Future<List<String>> getAvailableColorGroups() async {
    final library = await getFullLibrary();
    return library.getAvailableColorGroups();
  }

  static Future<NailColor?> findColorById(String id) async {
    await getFullLibrary();
    return resolveColor(id);
  }

  static Future<NailMaterial?> findMaterialById(String id) async {
    await getFullLibrary();
    return resolveMaterial(id);
  }

  /// Сброс кэша. Вызывать после изменения пользовательских данных.
  static void invalidateCache() {
    _unifiedLibrary = null;
  }

  static Future<DesignLibrary> reload() async {
    invalidateCache();
    return getFullLibrary();
  }
}