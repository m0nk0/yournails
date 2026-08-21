import 'package:flutter/material.dart';
import '../models/nail_material.dart';
import '../services/design_sets_service.dart';

class MaterialPickerScreen extends StatelessWidget {
  final NailMaterial? selectedMaterial;
  final Color previewColor;

  const MaterialPickerScreen({
    super.key,
    this.selectedMaterial,
    required this.previewColor,
  });

  @override
  Widget build(BuildContext context) {
    final materials = DesignSetsService.getMaterials();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор материала', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: materials.length,
        itemBuilder: (context, index) {
          final material = materials[index];
          final isSelected = selectedMaterial?.id == material.id;

          return GestureDetector(
            onTap: () => Navigator.pop(context, material),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Превью цвета с эффектом материала
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: MaterialPreview(
                          baseColor: previewColor,
                          material: material,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Информация
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            material.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.pink : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            material.description,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    // Индикатор выбора
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.pink, size: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Виджет превью цвета с эффектом материала (мягкий глянец)
class MaterialPreview extends StatelessWidget {
  final Color baseColor;
  final NailMaterial material;

  const MaterialPreview({
    super.key,
    required this.baseColor,
    required this.material,
  });

  @override
  Widget build(BuildContext context) {
    // Применяем насыщенность
    final hsl = HSLColor.fromColor(baseColor);
    final adjustedColor = hsl
        .withSaturation((hsl.saturation * material.saturation).clamp(0.0, 1.0))
        .toColor();

    return Stack(
      children: [
        // Базовый цвет с прозрачностью
        Positioned.fill(
          child: Opacity(
            opacity: material.opacity,
            child: Container(color: adjustedColor),
          ),
        ),
        // МЯГКИЙ глянец (исправлено)
        if (material.hasGloss)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(material.glossIntensity * 0.30),
                    Colors.white.withOpacity(material.glossIntensity * 0.10),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.7],
                ),
              ),
            ),
          ),
      ],
    );
  }
}