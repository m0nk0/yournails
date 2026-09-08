import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/nail_pattern.dart';
import '../models/nail_shape.dart';
import '../models/selected_design.dart';
import '../library/unified_library_service.dart';

/// Снимок состояния экрана примерки (EditScreen).
/// Позволяет восстановить примерку после выхода на главный экран
/// и даже после перезапуска приложения.
class TryOnSession {
  final String photoPath;

  // Рамка ногтя
  final double frameCenterDx;
  final double frameCenterDy;
  final double frameWidth;
  final double frameHeight;
  final double rotation;

  // Фото (зум/смещение)
  final double imageOffsetDx;
  final double imageOffsetDy;
  final double imageScale;

  // Дизайн (рецепт)
  final String? colorId;
  final String? materialId;
  final int shapeIndex;
  final double density;
  final double brightness;
  final int patternTypeIndex;
  final int patternColorValue;
  final String? patternPath;
  final String? patternName;

  // 3D
  final double edgeDarken;
  final double highlightIntensity;
  final double shadowIntensity;

  // Кутикула
  final double cuticleWidth;
  final double cuticleDepth;
  final double cuticleLength;
  final int cuticleTone;
  final int? cuticleColorValue;

  final DateTime savedAt;

  TryOnSession({
    required this.photoPath,
    required this.frameCenterDx,
    required this.frameCenterDy,
    required this.frameWidth,
    required this.frameHeight,
    required this.rotation,
    required this.imageOffsetDx,
    required this.imageOffsetDy,
    required this.imageScale,
    this.colorId,
    this.materialId,
    required this.shapeIndex,
    required this.density,
    required this.brightness,
    required this.patternTypeIndex,
    required this.patternColorValue,
    this.patternPath,
    this.patternName,
    required this.edgeDarken,
    required this.highlightIntensity,
    required this.shadowIntensity,
    required this.cuticleWidth,
    required this.cuticleDepth,
    required this.cuticleLength,
    required this.cuticleTone,
    this.cuticleColorValue,
    required this.savedAt,
  });

  /// Восстановление SelectedDesign из сессии (ID резолвятся через
  /// единую библиотеку — работают и старые, и новые ID)
  SelectedDesign toDesign() {
    return SelectedDesign(
      color: UnifiedLibraryService.resolveColor(colorId),
      material: UnifiedLibraryService.resolveMaterial(materialId),
      shape: NailShape.values[shapeIndex.clamp(0, NailShape.values.length - 1)],
      density: density,
      brightness: brightness,
      pattern: NailPattern(
        type: NailPatternType
            .values[patternTypeIndex.clamp(0, NailPatternType.values.length - 1)],
        color: Color(patternColorValue),
      ),
      patternPath: patternPath,
      patternName: patternName,
      edgeDarken: edgeDarken,
      highlightIntensity: highlightIntensity,
      shadowIntensity: shadowIntensity,
      cuticleWidth: cuticleWidth,
      cuticleDepth: cuticleDepth,
      cuticleLength: cuticleLength,
      cuticleTone: cuticleTone,
      cuticleColor: cuticleColorValue != null ? Color(cuticleColorValue!) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photoPath': photoPath,
      'frameCenterDx': frameCenterDx,
      'frameCenterDy': frameCenterDy,
      'frameWidth': frameWidth,
      'frameHeight': frameHeight,
      'rotation': rotation,
      'imageOffsetDx': imageOffsetDx,
      'imageOffsetDy': imageOffsetDy,
      'imageScale': imageScale,
      'colorId': colorId,
      'materialId': materialId,
      'shapeIndex': shapeIndex,
      'density': density,
      'brightness': brightness,
      'patternTypeIndex': patternTypeIndex,
      'patternColorValue': patternColorValue,
      'patternPath': patternPath,
      'patternName': patternName,
      'edgeDarken': edgeDarken,
      'highlightIntensity': highlightIntensity,
      'shadowIntensity': shadowIntensity,
      'cuticleWidth': cuticleWidth,
      'cuticleDepth': cuticleDepth,
      'cuticleLength': cuticleLength,
      'cuticleTone': cuticleTone,
      'cuticleColorValue': cuticleColorValue,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory TryOnSession.fromJson(Map<String, dynamic> json) {
    return TryOnSession(
      photoPath: json['photoPath'] as String,
      frameCenterDx: (json['frameCenterDx'] as num).toDouble(),
      frameCenterDy: (json['frameCenterDy'] as num).toDouble(),
      frameWidth: (json['frameWidth'] as num).toDouble(),
      frameHeight: (json['frameHeight'] as num).toDouble(),
      rotation: (json['rotation'] as num).toDouble(),
      imageOffsetDx: (json['imageOffsetDx'] as num).toDouble(),
      imageOffsetDy: (json['imageOffsetDy'] as num).toDouble(),
      imageScale: (json['imageScale'] as num).toDouble(),
      colorId: json['colorId'] as String?,
      materialId: json['materialId'] as String?,
      shapeIndex: (json['shapeIndex'] as num?)?.toInt() ?? 0,
      density: (json['density'] as num?)?.toDouble() ?? 2.0,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 1.0,
      patternTypeIndex: (json['patternTypeIndex'] as num?)?.toInt() ?? 0,
      patternColorValue: (json['patternColorValue'] as num?)?.toInt() ?? 0xFFFFFFFF,
      patternPath: json['patternPath'] as String?,
      patternName: json['patternName'] as String?,
      edgeDarken: (json['edgeDarken'] as num?)?.toDouble() ?? 0.3,
      highlightIntensity: (json['highlightIntensity'] as num?)?.toDouble() ?? 0.5,
      shadowIntensity: (json['shadowIntensity'] as num?)?.toDouble() ?? 0.4,
      cuticleWidth: (json['cuticleWidth'] as num?)?.toDouble() ?? 0.5,
      cuticleDepth: (json['cuticleDepth'] as num?)?.toDouble() ?? 0.5,
      cuticleLength: (json['cuticleLength'] as num?)?.toDouble() ?? 0.8,
      cuticleTone: (json['cuticleTone'] as num?)?.toInt() ?? 1,
      cuticleColorValue: (json['cuticleColorValue'] as num?)?.toInt(),
      savedAt: json['savedAt'] != null
          ? DateTime.parse(json['savedAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Хранение сессии примерки в Hive (переживает перезапуск приложения).
class TryOnSessionService {
  static Box? _box;
  static const String _key = 'current';

  static Future<Box> _getBox() async {
    return _box ??= await Hive.openBox('tryon_session');
  }

  static Future<TryOnSession?> load() async {
    try {
      final box = await _getBox();
      final raw = box.get(_key);
      if (raw == null) return null;
      return TryOnSession.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(TryOnSession session) async {
    try {
      final box = await _getBox();
      await box.put(_key, session.toJson());
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.delete(_key);
    } catch (_) {}
  }
}