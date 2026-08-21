import 'package:flutter/material.dart';

/// Модель цвета ногтя.
class NailColor {
  final String id;
  final String name;
  final Color color;
  final String group;

  NailColor({
    required this.id,
    required this.name,
    required this.color,
    this.group = 'basic',
  });
}