import 'package:flutter/material.dart';

import '../models/nail_material.dart';
import '../library/unified_library_service.dart';
import '../utils/top_message.dart';
import 'material_editor_screen.dart';

/// Экран выбора материала.
/// Источники данных — Единая Библиотека (встроенные + пользовательские материалы).
/// Добавлена кнопка «+» в AppBar и плитка «Создать материал» в конце списка.
/// Долгое нажатие по своему материалу = удаление с подтверждением.
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

  /// Свой материал — ID содержит 'custom'
  bool _isCustom(NailMaterial m) => m.id.contains('custom');

  /// Открыть редактор материала; после возврата — перезагрузить список
  Future<void> _openEditor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MaterialEditorScreen()),
    );
    if (result == true) {
      await _load();
      if (mounted) {
        TopMessage.show(context, 'Материал добавлен в библиотеку',
            color: Colors.green);
      }
    }
  }

  /// Удалить свой материал с подтверждением
  Future<void> _deleteMaterial(NailMaterial material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить материал?', style: TextStyle(fontSize: 20)),
        content: Text('"${material.name}" будет удалён из библиотеки.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await UnifiedLibraryService.deleteCustomMaterial(material.id);
        await _load();
        if (mounted) {
          TopMessage.show(context, 'Материал удалён', color: Colors.green);
        }
      } catch (e) {
        if (mounted) {
          TopMessage.show(context, 'Ошибка удаления: $e', color: Colors.red);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор материала', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            tooltip: 'Создать материал',
            onPressed: _openEditor,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _materials.length + 1, // +1 для плитки «Создать»
              itemBuilder: (context, index) {
                // Плитка «Создать материал» в конце списка
                if (index == _materials.length) {
                  return _buildCreateTile();
                }

                final material = _materials[index];
                final isSelected = _isSelected(material);
                final isCustom = _isCustom(material);

                return GestureDetector(
                  onTap: () => Navigator.pop(context, material),
                  onLongPress:
                      isCustom ? () => _deleteMaterial(material) : null,
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        material.name,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.pink
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (isCustom)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.pink[50],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: Colors.pink[200]!),
                                        ),
                                        child: const Text(
                                          'мой',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.pink,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  material.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (isCustom)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Долгое нажатие = удалить',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
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

  /// Плитка «Создать материал» в конце списка
  Widget _buildCreateTile() {
    return GestureDetector(
      onTap: _openEditor,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.pink, width: 2),
                ),
                child: const Icon(Icons.add, color: Colors.pink, size: 32),
              ),
              const SizedBox(width: 16),
              const Text(
                'Создать материал',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
            ],
          ),
        ),
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
                    Colors.white.withValues(alpha: material.glossIntensity * 0.30),
                    Colors.white.withValues(alpha: material.glossIntensity * 0.10),
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