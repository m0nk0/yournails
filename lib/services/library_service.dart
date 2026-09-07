import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/nail_color.dart';
import '../models/nail_material.dart';

/// Единая Библиотека мастера: один JSON-манифест library.json.
/// Секции: colors / materials / patterns / palettes / catalog.
class LibraryService {
  static const int schemaVersion = 1;
  static Map<String, dynamic>? _m;

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/library.json');
  }

  /// Загрузка манифеста (одноразово). Если файла нет — создаёт пустой.
  static Future<void> init() async {
    if (_m != null) return;
    final f = await _file();
    if (await f.exists()) {
      try {
        _m = Map<String, dynamic>.from(
            jsonDecode(await f.readAsString()) as Map);
      } catch (_) {
        _m = null;
      }
    }
    if (_m == null) {
      _m = {
        'version': schemaVersion,
        'colors': <dynamic>[],
        'materials': <dynamic>[],
        'patterns': <dynamic>[],
        'palettes': <dynamic>[],
        'catalog': <dynamic>[],
      };
      await _migrateOldColors();
      await _save();
    }
    // Страховка от старых версий файла: недостающие секции
    for (final key in ['colors', 'materials', 'patterns', 'palettes', 'catalog']) {
      _m!.putIfAbsent(key, () => <dynamic>[]);
    }
  }

  /// Одноразовая миграция «Моих цветов» из custom_colors.json
  static Future<void> _migrateOldColors() async {
    final dir = await getApplicationDocumentsDirectory();
    final old = File('${dir.path}/custom_colors.json');
    if (!await old.exists()) return;
    try {
      final list = jsonDecode(await old.readAsString()) as List;
      final now = DateTime.now().toIso8601String();
      for (final e in list) {
        (_m!['colors'] as List).add({
          'id': e['id'],
          'name': e['name'],
          'value': e['value'],
          'createdAt': now,
        });
      }
      // Старый файл не удаляем — переименовываем в бэкап
      await old.rename('${dir.path}/custom_colors.json.bak');
    } catch (_) {}
  }

  static Future<void> _save() async {
    final f = await _file();
    await f.writeAsString(jsonEncode(_m));
  }

  // ============ ЦВЕТА ============

  static Future<List<NailColor>> getCustomColors() async {
    await init();
    return (_m!['colors'] as List)
        .map((e) => NailColor(
              id: e['id'] as String,
              name: e['name'] as String,
              color: Color(e['value'] as int),
              group: 'my',
            ))
        .toList();
  }

  static Future<List<NailColor>> addCustomColor(String name, Color color) async {
    await init();
    (_m!['colors'] as List).add({
      'id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'value': color.value,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _save();
    return getCustomColors();
  }

  static Future<List<NailColor>> deleteCustomColor(String id) async {
    await init();
    (_m!['colors'] as List).removeWhere((e) => e['id'] == id);
    await _save();
    return getCustomColors();
  }

  // ============ МАТЕРИАЛЫ (задел на Этап 2) ============

  static Future<List<NailMaterial>> getCustomMaterials() async {
    await init();
    return (_m!['materials'] as List)
        .map((e) => NailMaterial(
              id: e['id'] as String,
              name: e['name'] as String,
              description: (e['description'] as String?) ?? 'Свой материал',
              opacity: (e['opacity'] as num?)?.toDouble() ?? 1.0,
              saturation: (e['saturation'] as num?)?.toDouble() ?? 1.0,
              hasGloss: (e['hasGloss'] as bool?) ?? true,
              glossIntensity: (e['glossIntensity'] as num?)?.toDouble() ?? 0.5,
            ))
        .toList();
  }

  static Future<void> addCustomMaterial(NailMaterial m) async {
    await init();
    (_m!['materials'] as List).add({
      'id': m.id,
      'name': m.name,
      'description': m.description,
      'opacity': m.opacity,
      'saturation': m.saturation,
      'hasGloss': m.hasGloss,
      'glossIntensity': m.glossIntensity,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _save();
  }

  static Future<void> deleteCustomMaterial(String id) async {
    await init();
    (_m!['materials'] as List).removeWhere((e) => e['id'] == id);
    await _save();
  }
}