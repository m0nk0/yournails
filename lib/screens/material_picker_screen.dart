import 'package:flutter/material.dart';

import '../models/nail_material.dart';
import '../library/unified_library_service.dart';

/// Экран выбора материала.
/// Источники данных — Единая Библиотека (встроенные + пользовательские материалы).
class MaterialPickerScreen extends StatefulWidget {
  final NailMaterial? selectedMaterial;
  final Color previewColor;

  const MaterialPickerScreen({
    super.key,
    this.selectedMaterial,
    required this.previewColor,
  });

  @override
  State<MaterialPickerScreen> createState() => _MaterialPickerScreenState();
}

class _MaterialPickerScreenState extends State<MaterialPickerScreen> {
  List<NailMaterial> _materials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final materials = await UnifiedLibraryService.getAllMaterials();
    if (!mounted) return;
    setState(() {
      _materials = materials;
      _loading = false;
    });
  }

  /// Проверяет, является ли [candidate] тем же материалом, что и выбранный.
  /// Работает и с новыми ID (`mat_gel_polish`), и со старыми (`gel_polish`):
  /// резолвит ID выбранного материала и сравнивает с кандидатом.
  bool _isSelected(NailMaterial candidate) {
    if (widget.selectedMaterial == null) return false;
    if (widget.selectedMaterial!.id == candidate.id) return true;
    // Попытка резолвить старый ID → сравнить с кандидатом
    final resolved = UnifiedLibraryService.resolveMaterial(
      widget.selectedMaterial!.id,
    );
    return resolved?.id == candidate.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор материала', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _materials.length,
              itemBuilder: (context, index) {
                final material = _materials[index];
                final isSelected = _isSelected(material);

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
                                baseColor: widget.previewColor,
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
                                    color: isSelected
                                        ? Colors.pink
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  material.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Индикатор выбора
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: Colors.pink, size: 32),
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
        // Мягкий глянец
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