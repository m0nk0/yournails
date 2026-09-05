import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/nail_color.dart';
import '../models/nail_material.dart';
import '../models/selected_design.dart';
import '../models/nail_shape.dart';
import '../models/nail_pattern.dart';
import '../models/my_design.dart';
import '../services/design_sets_service.dart';
import '../services/database_service.dart';
import '../utils/responsive.dart';
import '../utils/top_message.dart';
import '../widgets/nail_pattern_layer.dart';
import 'color_picker_screen.dart';
import 'material_picker_screen.dart';
import 'pattern_picker_screen.dart';

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

  void _applyMyDesign(MyDesign d) {
    setState(() {
           if (d.isRecipe) {
        _design = SelectedDesign(
          color: _findColor(d.colorId),
          material: _findMaterial(d.materialId),
          shape: d.shape,
          density: d.density,
          brightness: d.brightness,
          pattern: d.pattern,
          edgeDarken: d.edgeDarken,
          highlightIntensity: d.highlightIntensity,
          shadowIntensity: d.shadowIntensity,
          cuticleColor:
              d.cuticleColor != null ? Color(d.cuticleColor!) : null,
        );
      } else {
        _design = SelectedDesign(
          color: _design.color,
          material: _design.material,
          shape: _design.shape,
          density: _design.density,
          brightness: _design.brightness,
          pattern: _design.pattern,
          patternPath: d.imagePath,
          patternName: d.name,
        );
      }
    });
    // success-снэкбар убран — не закрывает кнопки
  }

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
          pattern: _design.pattern,
          patternPath: _design.patternPath,
          patternName: _design.patternName,
        );
      });
    }
  }

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
          pattern: _design.pattern,
          patternPath: _design.patternPath,
          patternName: _design.patternName,
        );
      });
    }
  }

  Future<void> _openPatternPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatternPickerScreen(
          currentPattern: _design.pattern,
          previewColor: _design.color?.color ?? Colors.pink,
        ),
      ),
    );

    if (result != null && result is NailPattern) {
      setState(() {
        _design = SelectedDesign(
          color: _design.color,
          material: _design.material,
          shape: _design.shape,
          density: _design.density,
          brightness: _design.brightness,
          pattern: result,
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
    final tablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор дизайна', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: tablet ? 720 : double.infinity,
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.pad(context)),
                color: Colors.pink[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ваш выбор:',
                      style: TextStyle(
                          fontSize: Responsive.fs(context, 18),
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Цвет: ${_design.color?.name ?? 'Не выбран'}',
                      style: TextStyle(fontSize: Responsive.fs(context, 16)),
                    ),
                    Text(
                      'Материал: ${_design.material?.name ?? 'Не выбран'}',
                      style: TextStyle(fontSize: Responsive.fs(context, 16)),
                    ),
                    Text(
                      'Рисунок: ${NailPattern.getTypeName(_design.pattern.type)}',
                      style: TextStyle(fontSize: Responsive.fs(context, 16)),
                    ),
                    if (_design.hasPattern)
                      Text(
                        'Узор-картинка: ${_design.patternName}',
                        style: TextStyle(
                            fontSize: Responsive.fs(context, 16),
                            color: Colors.pink),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(Responsive.pad(context)),
                  children: [
                    Text(
                      'Мои дизайны',
                      style: TextStyle(
                          fontSize: Responsive.fs(context, 20),
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Тап — применить • Долгое нажатие — удалить',
                      style: TextStyle(
                          fontSize: Responsive.fs(context, 12),
                          color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: tablet ? 160 : 130,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildAddTile(),
                          ..._myDesigns.map((d) => _buildMyDesignTile(d)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSelectionCard(
                      icon: Icons.palette,
                      title: 'Цвет',
                      subtitle: _design.color?.name ?? 'Выберите цвет',
                      color: _design.color?.color ?? Colors.grey[300]!,
                      onTap: _openColorPicker,
                    ),
                    const SizedBox(height: 12),

                    _buildSelectionCard(
                      icon: Icons.diamond,
                      title: 'Материал',
                      subtitle: _design.material?.name ?? 'Выберите материал',
                      color: Colors.pink[100]!,
                      onTap: _openMaterialPicker,
                    ),
                    const SizedBox(height: 12),

                    _buildSelectionCard(
                      icon: Icons.auto_awesome,
                      title: 'Рисунок',
                      subtitle: NailPattern.getTypeName(_design.pattern.type),
                      color: _design.pattern.isNone
                          ? Colors.grey[300]!
                          : _design.pattern.color,
                      onTap: _openPatternPicker,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.all(Responsive.pad(context)),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _design.hasColor ? _applyDesign : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          vertical: tablet ? 18 : 16),
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Применить дизайн',
                      style: TextStyle(fontSize: Responsive.fs(context, 18)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddTile() {
    final tablet = Responsive.isTablet(context);
    return GestureDetector(
      onTap: _uploadImage,
      child: Container(
        width: tablet ? 110 : 90,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.pink[50],
          border: Border.all(color: Colors.pink, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate,
                color: Colors.pink, size: tablet ? 38 : 32),
            const SizedBox(height: 4),
            Text(
              'Загрузить',
              style: TextStyle(
                color: Colors.pink,
                fontSize: Responsive.fs(context, 12),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyDesignTile(MyDesign d) {
    final isSelected = d.isImage
        ? _design.patternPath == d.imagePath
        : _design.color?.id == d.colorId;
    final tablet = Responsive.isTablet(context);

    return GestureDetector(
      onTap: () => _applyMyDesign(d),
      onLongPress: () => _deleteMyDesign(d),
      child: Container(
        width: tablet ? 110 : 90,
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
              style: TextStyle(fontSize: Responsive.fs(context, 10)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipePreview(MyDesign d) {
    final color = _findColor(d.colorId)?.color ?? Colors.grey;
    final material = _findMaterial(d.materialId);

    return Stack(
      children: [
        Positioned.fill(child: Container(color: color)),
        Positioned.fill(
          child: NailPatternLayer(pattern: d.pattern),
        ),
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
          style: TextStyle(
              fontSize: Responsive.fs(context, 20),
              fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
              fontSize: Responsive.fs(context, 16),
              color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, size: 32),
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}