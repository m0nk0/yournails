import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/nail_color.dart';
import '../models/nail_material.dart';
import '../models/selected_design.dart';
import '../models/nail_shape.dart';
import '../models/my_design.dart';
import '../services/design_sets_service.dart';
import '../services/database_service.dart';
import 'color_picker_screen.dart';
import 'material_picker_screen.dart';

class DesignSelectionScreen extends StatefulWidget {
  final SelectedDesign currentDesign;

  const DesignSelectionScreen({super.key, required this.currentDesign});

  @override
  State<DesignSelectionScreen> createState() => _DesignSelectionScreenState();
}

class _DesignSelectionScreenState extends State<DesignSelectionScreen> {
  late SelectedDesign _design;
  List<MyDesign> _myDesigns = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _design = widget.currentDesign;
    _loadMyDesigns();
  }

  void _loadMyDesigns() {
    setState(() {
      _myDesigns = DatabaseService.getMyDesigns();
    });
  }

  NailColor? _findColor(String? id) {
    if (id == null) return null;
    for (final c in DesignSetsService.getColors()) {
      if (c.id == id) return c;
    }
    return null;
  }

  NailMaterial? _findMaterial(String? id) {
    if (id == null) return null;
    for (final m in DesignSetsService.getMaterials()) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Применить дизайн из коллекции
  void _applyMyDesign(MyDesign d) {
    setState(() {
      if (d.isRecipe) {
        // Рецепт: применяем все параметры
        _design = SelectedDesign(
          color: _findColor(d.colorId),
          material: _findMaterial(d.materialId),
          shape: d.shape,
          density: d.density,
          brightness: d.brightness,
        );
      } else {
        // Картинка: накладываем паттерн
        _design = SelectedDesign(
          color: _design.color,
          material: _design.material,
          shape: _design.shape,
          density: _design.density,
          brightness: _design.brightness,
          patternPath: d.imagePath,
          patternName: d.name,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Применено: ${d.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Удалить дизайн из коллекции
  Future<void> _deleteMyDesign(MyDesign d) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить дизайн?', style: TextStyle(fontSize: 20)),
        content: Text('"${d.name}" будет удалён из коллекции.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.deleteMyDesign(d.id);
      _loadMyDesigns();
    }
  }

  /// Загрузить PNG/фото из галереи или камеры
  Future<void> _uploadImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Загрузить дизайн', style: TextStyle(fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, size: 28),
              title: const Text('Из галереи', style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, size: 28),
              title: const Text('Сделать фото', style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final XFile? photo = await _picker.pickImage(source: source, imageQuality: 90);
    if (photo == null) return;

    final nameController = TextEditingController(text: 'Мой дизайн');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Название дизайна', style: TextStyle(fontSize: 20)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Название'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (ok == true && nameController.text.trim().isNotEmpty) {
      final savedPath = await DatabaseService.savePhoto(File(photo.path), 'pattern');
      await DatabaseService.addMyDesign(MyDesign(
        id: const Uuid().v4(),
        name: nameController.text.trim(),
        type: MyDesignType.image,
        imagePath: savedPath,
        createdAt: DateTime.now(),
      ));
      _loadMyDesigns();
    }
  }

  /// Открыть выбор цвета
  Future<void> _openColorPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ColorPickerScreen(selectedColor: _design.color),
      ),
    );

    if (result != null) {
      setState(() {
        _design = SelectedDesign(
          color: result,
          material: _design.material,
          shape: _design.shape,
          density: _design.density,
          brightness: _design.brightness,
          patternPath: _design.patternPath,
          patternName: _design.patternName,
        );
      });
    }
  }

  /// Открыть выбор материала
  Future<void> _openMaterialPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialPickerScreen(
          selectedMaterial: _design.material,
          previewColor: _design.color?.color ?? Colors.pink,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _design = SelectedDesign(
          color: _design.color,
          material: result,
          shape: _design.shape,
          density: _design.density,
          brightness: _design.brightness,
          patternPath: _design.patternPath,
          patternName: _design.patternName,
        );
      });
    }
  }

  void _applyDesign() {
    Navigator.pop(context, _design);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор дизайна', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Превью текущего выбора
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.pink[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ваш выбор:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Цвет: ${_design.color?.name ?? 'Не выбран'}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Материал: ${_design.material?.name ?? 'Не выбран'}',
                  style: const TextStyle(fontSize: 16),
                ),
                if (_design.hasPattern)
                  Text(
                    'Узор: ${_design.patternName}',
                    style: const TextStyle(fontSize: 16, color: Colors.pink),
                  ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // НОВОЕ: Мои дизайны
                const Text(
                  'Мои дизайны',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Тап — применить • Долгое нажатие — удалить',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 130,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildAddTile(),
                      ..._myDesigns.map((d) => _buildMyDesignTile(d)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Цвет
                _buildSelectionCard(
                  icon: Icons.palette,
                  title: 'Цвет',
                  subtitle: _design.color?.name ?? 'Выберите цвет',
                  color: _design.color?.color ?? Colors.grey[300]!,
                  onTap: _openColorPicker,
                ),
                const SizedBox(height: 12),

                // Материал
                _buildSelectionCard(
                  icon: Icons.diamond,
                  title: 'Материал',
                  subtitle: _design.material?.name ?? 'Выберите материал',
                  color: Colors.pink[100]!,
                  onTap: _openMaterialPicker,
                ),
              ],
            ),
          ),

          // Кнопка применить
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _design.hasColor ? _applyDesign : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Применить дизайн',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Плитка загрузки нового дизайна
  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _uploadImage,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.pink[50],
          border: Border.all(color: Colors.pink, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, color: Colors.pink, size: 32),
            SizedBox(height: 4),
            Text(
              'Загрузить',
              style: TextStyle(
                color: Colors.pink,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Плитка дизайна из коллекции
  Widget _buildMyDesignTile(MyDesign d) {
    final isSelected = d.isImage
        ? _design.patternPath == d.imagePath
        : _design.color?.id == d.colorId;

    return GestureDetector(
      onTap: () => _applyMyDesign(d),
      onLongPress: () => _deleteMyDesign(d),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.pink : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: d.isImage
                      ? Image.file(
                          File(d.imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : _buildRecipePreview(d),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              d.name,
              style: const TextStyle(fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Миниатюра рецепта (рисуется программно)
  Widget _buildRecipePreview(MyDesign d) {
    final color = _findColor(d.colorId)?.color ?? Colors.grey;
    final material = _findMaterial(d.materialId);

    return Stack(
      children: [
        Positioned.fill(child: Container(color: color)),
        if (material?.hasGloss ?? false)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity((material?.glossIntensity ?? 0.5) * 0.30),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
            ),
          ),
        const Positioned(
          top: 2,
          right: 2,
          child: Icon(Icons.bookmark, size: 14, color: Colors.white70),
        ),
      ],
    );
  }

  /// Карточка выбора
  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, size: 32),
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}