import 'package:flutter/material.dart';
import 'nail_shape.dart';
import 'nail_pattern.dart';

/// Тип дизайна в коллекции
enum MyDesignType { recipe, image }

/// Дизайн из коллекции мастера
class MyDesign {
  final String id;
  final String name;
  final MyDesignType type;

  // Для рецепта
  final String? colorId;
  final String? materialId;
  final String? shapeName;
  final double density;
  final double brightness;
  final String? patternType;
  final int? patternColor;
  final double edgeDarken;
  final double highlightIntensity;
  final double shadowIntensity;

  // Для картинки
  final String? imagePath;

  final DateTime createdAt;

  MyDesign({
    required this.id,
    required this.name,
    required this.type,
    this.colorId,
    this.materialId,
    this.shapeName,
    this.density = 2.0,
    this.brightness = 1.0,
    this.patternType,
    this.patternColor,
    this.edgeDarken = 0.3,
    this.highlightIntensity = 0.5,
    this.shadowIntensity = 0.4,
    this.imagePath,
    required this.createdAt,
  });

  bool get isRecipe => type == MyDesignType.recipe;
  bool get isImage => type == MyDesignType.image;

  NailShape get shape {
    if (shapeName == null) return NailShape.oval;
    return NailShape.values.firstWhere(
      (s) => s.name == shapeName,
      orElse: () => NailShape.oval,
    );
  }

  NailPattern get pattern {
    if (patternType == null) return const NailPattern();
    return NailPattern(
      type: NailPatternType.values.firstWhere(
        (t) => t.name == patternType,
        orElse: () => NailPatternType.none,
      ),
      color: Color(patternColor ?? 0xFFFFFFFF),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'colorId': colorId,
      'materialId': materialId,
      'shapeName': shapeName,
      'density': density,
      'brightness': brightness,
      'patternType': patternType,
      'patternColor': patternColor,
      'edgeDarken': edgeDarken,
      'highlightIntensity': highlightIntensity,
      'shadowIntensity': shadowIntensity,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MyDesign.fromMap(Map<String, dynamic> map) {
    return MyDesign(
      id: map['id'] as String,
      name: map['name'] as String,
      type: MyDesignType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => MyDesignType.recipe,
      ),
      colorId: map['colorId'] as String?,
      materialId: map['materialId'] as String?,
      shapeName: map['shapeName'] as String?,
      density: (map['density'] as num?)?.toDouble() ?? 2.0,
      brightness: (map['brightness'] as num?)?.toDouble() ?? 1.0,
      patternType: map['patternType'] as String?,
      patternColor: map['patternColor'] as int?,
      edgeDarken: (map['edgeDarken'] as num?)?.toDouble() ?? 0.3,
      highlightIntensity: (map['highlightIntensity'] as num?)?.toDouble() ?? 0.5,
      shadowIntensity: (map['shadowIntensity'] as num?)?.toDouble() ?? 0.4,
      imagePath: map['imagePath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}