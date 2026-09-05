import 'package:flutter/material.dart';
import 'nail_shape.dart';
import 'nail_pattern.dart';

/// Тип сохранённого дизайна
enum MyDesignType { recipe, image }

/// Сохранённый дизайн мастера (рецепт или PNG-картинка)
class MyDesign {
  final String id;
  final String name;
  final MyDesignType type;

  // Для рецепта
  final String? colorId;
  final String? materialId;
  final String shapeName;
  final double density;
  final double brightness;
  final String? patternType;
  final int? patternColor;
  final double edgeDarken;
  final double highlightIntensity;
  final double shadowIntensity;
  final int? cuticleColor; // цвет кожи клиента (пипетка), null = по тону

  // Для картинки
  final String? imagePath;

  final DateTime createdAt;

  MyDesign({
    required this.id,
    required this.name,
    required this.type,
    this.colorId,
    this.materialId,
    this.shapeName = 'oval',
    this.density = 2.0,
    this.brightness = 1.0,
    this.patternType,
    this.patternColor,
    this.edgeDarken = 0.3,
    this.highlightIntensity = 0.5,
    this.shadowIntensity = 0.4,
    this.cuticleColor,
    this.imagePath,
    required this.createdAt,
  });

  bool get isRecipe => type == MyDesignType.recipe;
  bool get isImage => type == MyDesignType.image;

  NailShape get shape => NailShape.values.firstWhere(
        (s) => s.name == shapeName,
        orElse: () => NailShape.oval,
      );

  NailPattern get pattern => patternType == null
      ? const NailPattern()
      : NailPattern(
          type: NailPatternType.values.firstWhere(
            (t) => t.name == patternType,
            orElse: () => NailPatternType.none,
          ),
          color: Color(patternColor ?? 0xFFFFFFFF),
        );

  Map<String, dynamic> toMap() => {
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
        'cuticleColor': cuticleColor,
        'imagePath': imagePath,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory MyDesign.fromMap(Map<String, dynamic> m) => MyDesign(
        id: m['id'] as String,
        name: m['name'] as String,
        type: MyDesignType.values.firstWhere(
          (t) => t.name == m['type'],
          orElse: () => MyDesignType.recipe,
        ),
        colorId: m['colorId'] as String?,
        materialId: m['materialId'] as String?,
        shapeName: (m['shapeName'] as String?) ?? 'oval',
        density: (m['density'] as num?)?.toDouble() ?? 2.0,
        brightness: (m['brightness'] as num?)?.toDouble() ?? 1.0,
        patternType: m['patternType'] as String?,
        patternColor: m['patternColor'] as int?,
        edgeDarken: (m['edgeDarken'] as num?)?.toDouble() ?? 0.3,
        highlightIntensity: (m['highlightIntensity'] as num?)?.toDouble() ?? 0.5,
        shadowIntensity: (m['shadowIntensity'] as num?)?.toDouble() ?? 0.4,
        cuticleColor: m['cuticleColor'] as int?,
        imagePath: m['imagePath'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      );
}