import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/nail_color.dart';
import '../models/nail_material.dart';
import '../models/nail_pattern.dart';
import 'design_library.dart';
import 'library_manifest.dart';
import 'builtin/builtin_colors.dart';
import 'builtin/default_library_data.dart';

/// Сервис для загрузки и предоставления доступа к встроенной (базовой) библиотеке.
/// Цвета берутся из типизированного списка, материалы и паттерны — из JSON.
class BuiltinLibraryService {
  static DesignLibrary? _library;

  /// Инициализация и сборка встроенной библиотеки.
  /// Выполняется однократно при первом обращении.
  static Future<DesignLibrary> getLibrary() async {
    if (_library != null) {
      return _library!;
    }

    try {
      final Map<String, dynamic> jsonData = jsonDecode(defaultLibraryJson) as Map<String, dynamic>;
      
      // Парсим манифест
      final manifest = LibraryManifest.fromJson(
        jsonData['manifest'] as Map<String, dynamic>,
      );

      // Материалы из JSON
      final materials = (jsonData['materials'] as List<dynamic>? ?? [])
          .map((e) => NailMaterial(
                id: e['id'] as String,
                name: e['name'] as String,
                description: e['description'] as String? ?? '',
                opacity: (e['opacity'] as num?)?.toDouble() ?? 1.0,
                saturation: (e['saturation'] as num?)?.toDouble() ?? 1.0,
                hasGloss: e['hasGloss'] as bool? ?? true,
                glossIntensity: (e['glossIntensity'] as num?)?.toDouble() ?? 0.5,
              ))
          .toList();

      // Паттерны из JSON
      final patterns = (jsonData['patterns'] as List<dynamic>? ?? [])
          .map((e) => NailPattern(
                type: NailPatternType.values.firstWhere(
                  (t) => t.name == e['type'],
                  orElse: () => NailPatternType.none,
                ),
                color: Color(e['colorValue'] as int? ?? 0xFFFFFFFF),
              ))
          .toList();

      // Цвета из типизированного списка
      _library = DesignLibrary(
        manifest: manifest,
        colors: builtinColors,
        materials: materials,
        patterns: patterns,
      );
    } catch (e) {
      // Fallback: если парсинг не удался, возвращаем библиотеку хотя бы с цветами
      _library = DesignLibrary(
        manifest: LibraryManifest(
          version: 1,
          colorCount: builtinColors.length,
          materialCount: 0,
          patternCount: 0,
          colorGroups: [],
          lastUpdated: DateTime.now(),
        ),
        colors: builtinColors,
        materials: [],
        patterns: [],
      );
    }
    
    return _library!;
  }

  /// Получить все встроенные цвета
  static Future<List<NailColor>> getBuiltinColors() async {
    final library = await getLibrary();
    return library.colors;
  }

  /// Получить все встроенные материалы
  static Future<List<NailMaterial>> getBuiltinMaterials() async {
    final library = await getLibrary();
    return library.materials;
  }

  /// Получить все встроенные паттерны
  static Future<List<NailPattern>> getBuiltinPatterns() async {
    final library = await getLibrary();
    return library.patterns;
  }

  /// Получить цвет по ID из встроенной библиотеки
  static Future<NailColor?> getBuiltinColorById(String id) async {
    final library = await getLibrary();
    return library.getColorById(id);
  }

  /// Получить материал по ID из встроенной библиотеки
  static Future<NailMaterial?> getBuiltinMaterialById(String id) async {
    final library = await getLibrary();
    return library.getMaterialById(id);
  }

  /// Сброс кэша (полезно для тестов или принудительного обновления)
  static void resetCache() {
    _library = null;
  }
}