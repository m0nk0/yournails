import 'dart:io';
import 'package:image/image.dart' as img;
import '../models/nail_zone.dart';

/// Сервис наложения дизайна на фото руки.
/// Реализация будет добавлена на Фазе 1.
class OverlayService {
  /// Накладывает дизайн на все зоны ногтей.
  static Future<File> overlayDesigns({
    required File handImage,
    required File nailDesign,
    required List<NailZone> zones,
    required String outputPath,
  }) async {
    // TODO: Реализовать на Фазе 1
    throw UnimplementedError('Метод будет реализован на Фазе 1');
  }

  /// Накладывает дизайн на одну зону ногтя.
  static img.Image applyDesignToZone({
    required img.Image image,
    required img.Image design,
    required NailZone zone,
  }) {
    // TODO: Реализовать на Фазе 1
    throw UnimplementedError('Метод будет реализован на Фазе 1');
  }
}