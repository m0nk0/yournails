import 'package:flutter/material.dart';

import '../models/nail_color.dart';
import '../models/nail_material.dart';
import '../models/nail_pattern.dart';
import 'library_manifest.dart';

/// Модель единой библиотеки дизайнов.
/// Объединяет манифест и все доступные элементы (цвета, материалы, паттерны).
class DesignLibrary {
  final LibraryManifest manifest;
  final List<NailColor> colors;
  final List<NailMaterial> materials;
  final List<NailPattern> patterns;

  DesignLibrary({
    required this.manifest,
    required this.colors,
    required this.materials,
    required this.patterns,
  });

  factory DesignLibrary.fromJson(Map<String, dynamic> json) {
    final manifestJson = json['manifest'] as Map<String, dynamic>? ?? {};
    final manifest = LibraryManifest.fromJson(manifestJson);

    final colors = (json['colors'] as List<dynamic>? ?? [])
        .map((e) => NailColor(
              id: e['id'] as String,
              name: e['name'] as String,
              color: Color(e['value'] as int),
              group: e['group'] as String? ?? 'basic',
            ))
        .toList();

    final materials = (json['materials'] as List<dynamic>? ?? [])
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

    final patterns = (json['patterns'] as List<dynamic>? ?? [])
        .map((e) => NailPattern(
              type: NailPatternType.values.firstWhere(
                (t) => t.name == e['type'],
                orElse: () => NailPatternType.none,
              ),
              color: Color(e['colorValue'] as int? ?? 0xFFFFFFFF),
            ))
        .toList();

    return DesignLibrary(
      manifest: manifest,
      colors: colors,
      materials: materials,
      patterns: patterns,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'manifest': manifest.toJson(),
      'colors': colors.map((c) => {
            'id': c.id,
            'name': c.name,
            'value': c.color.toARGB32(),
            'group': c.group,
          }).toList(),
      'materials': materials.map((m) => {
            'id': m.id,
            'name': m.name,
            'description': m.description,
            'opacity': m.opacity,
            'saturation': m.saturation,
            'hasGloss': m.hasGloss,
            'glossIntensity': m.glossIntensity,
          }).toList(),
      'patterns': patterns.map((p) => {
            'type': p.type.name,
            'colorValue': p.color.toARGB32(),
          }).toList(),
    };
  }

  /// Получить цвет по ID
  NailColor? getColorById(String id) {
    try {
      return colors.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Получить материал по ID
  NailMaterial? getMaterialById(String id) {
    try {
      return materials.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Получить цвета по группе
  List<NailColor> getColorsByGroup(String group) {
    return colors.where((c) => c.group == group).toList();
  }

  /// Получить все доступные группы цветов
  List<String> getAvailableColorGroups() {
    return colors.map((c) => c.group).toSet().toList();
  }
}