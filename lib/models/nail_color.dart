import 'package:flutter/material.dart';

/// Модель цвета ногтя.
class NailColor {
  final String id;
  final String name;
  final Color color;
  final String group;

  /// Необязательное описание-рецепт (для цветов из миксера):
  /// «Классический красный + Слоновая кость · белила 15%, смесь 42/58»
  final String? description;

  NailColor({
    required this.id,
    required this.name,
    required this.color,
    this.group = 'basic',
    this.description,
  });
}