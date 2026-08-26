import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/nail_color.dart';

/// Хранение пользовательских ("Моих") цветов в JSON-файле
class CustomColorService {
  static List<NailColor>? _cache;

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/custom_colors.json');
  }

  static Future<List<NailColor>> load() async {
    if (_cache != null) return _cache!;
    final f = await _file();
    if (!await f.exists()) {
      _cache = [];
      return _cache!;
    }
    try {
      final raw = await f.readAsString();
      final list = jsonDecode(raw) as List;
      _cache = list
          .map((e) => NailColor(
                id: e['id'] as String,
                name: e['name'] as String,
                color: Color(e['value'] as int),
                group: 'my',
              ))
          .toList();
    } catch (_) {
      _cache = [];
    }
    return _cache!;
  }

  static Future<List<NailColor>> add(String name, Color color) async {
    await load();
    _cache!.add(NailColor(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      color: color,
      group: 'my',
    ));
    await _save();
    return _cache!;
  }

  static Future<List<NailColor>> delete(String id) async {
    await load();
    _cache!.removeWhere((c) => c.id == id);
    await _save();
    return _cache!;
  }

  static Future<void> _save() async {
    final f = await _file();
    final data = _cache!
        .map((c) => {
              'id': c.id,
              'name': c.name,
              'value': c.color.value,
            })
        .toList();
    await f.writeAsString(jsonEncode(data));
  }
}