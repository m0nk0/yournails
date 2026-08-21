import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/nail_zone.dart';
import '../models/selected_design.dart';
import '../models/nail_shape.dart';

class ResultScreen extends StatelessWidget {
  final File imageFile;
  final NailZone zone;
  final SelectedDesign design;
  final Offset imageOffset;
  final double imageScale;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.zone,
    required this.design,
    required this.imageOffset,
    required this.imageScale,
  });

  @override
  Widget build(BuildContext context) {
    // Итоговый рендер с учётом всех параметров
    final render = design.getRender();
    final material = design.material;
    final borderRadius = NailShapeHelper.getBorderRadius(design.shape, zone.width, zone.height);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Фото с тем же смещением и масштабом
          Positioned.fill(
            child: Transform.translate(
              offset: imageOffset,
              child: Transform.scale(
                scale: imageScale,
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Наложение дизайна с формой и эффектами
          Positioned(
            left: zone.x - zone.width / 2,
            top: zone.y - zone.height / 2,
            child: Transform.rotate(
              angle: zone.rotation * math.pi / 180,
              child: ClipRRect(
                borderRadius: borderRadius,
                child: SizedBox(
                  width: zone.width,
                  height: zone.height,
                  child: Stack(
                    children: [
                      // Итоговый цвет с прозрачностью
                      Positioned.fill(
                        child: Opacity(
                          opacity: render.opacity,
                          child: Container(color: render.color),
                        ),
                      ),
                      // Мягкий глянец
                      if (material?.hasGloss ?? false)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity((material?.glossIntensity ?? 0.5) * 0.30),
                                  Colors.white.withOpacity((material?.glossIntensity ?? 0.5) * 0.10),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.3, 0.7],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Информационная панель внизу
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: render.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${design.color?.name ?? 'Цвет'} • ${design.density.toInt()} сл. • ${NailShapeHelper.getName(design.shape)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: const Text('← Назад'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Сохранение будет в следующем шаге'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Сохранить'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}