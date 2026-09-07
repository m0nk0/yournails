import 'package:flutter/material.dart';
import '../models/nail_color.dart';
import 'library_service.dart';

/// «Мои цвета» — тонкий прокси к единой Библиотеке (library.json).
/// Экраны (color_picker_screen, color_mixer_screen) продолжают
/// вызывать старые методы — там ничего менять не нужно.
class CustomColorService {
  /// Загрузить все свои цвета
  static Future<List<NailColor>> load() => LibraryService.getCustomColors();

  /// Добавить новый цвет (из миксера)
  static Future<List<NailColor>> add(String name, Color color) =>
      LibraryService.addCustomColor(name, color);

  /// Удалить цвет по id
  static Future<List<NailColor>> delete(String id) =>
      LibraryService.deleteCustomColor(id);
}