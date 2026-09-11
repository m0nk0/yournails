import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/nail_color.dart';
import '../models/nail_material.dart';
import '../models/selected_design.dart';
import '../models/nail_pattern.dart';
import '../models/my_design.dart';
import '../services/database_service.dart';
import '../library/unified_library_service.dart';
import '../utils/chroma_key.dart';
import '../utils/responsive.dart';
import '../widgets/nail_3d_renderer.dart';
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
    _myDesigns = DatabaseService.getMyDesigns();
    // Прогреваем кэш единой библиотеки в фоне (не блокируем UI)
    UnifiedLibraryService.getFullLibrary();
  }

  /// Поиск цвета с поддержкой старых ID (классика + тренды) и новых
  NailColor? _findColor(String? id) => UnifiedLibraryService.resolveColor(id);

  /// Поиск материала с поддержкой старых и новых ID
  NailMaterial? _findMaterial(String? id) =>
      UnifiedLibraryService.resolveMaterial(id);

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
      setState(() {
        _myDesigns = DatabaseService.getMyDesigns();
      });
    }
  }

  /// Загрузка своей картинки-дизайна (PNG/фото) с опцией chroma-key
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
              subtitle: const Text('PNG с прозрачностью = слайдер-дизайн',
                  style: TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, size: 28),
              title: const Text('Сделать фото', style: TextStyle(fontSize: 18)),
              subtitle: const Text('фото ляжет как принт',
                  style: TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final XFile? photo =
        await _picker.pickImage(source: source, imageQuality: 90);
    if (photo == null) return;

    final nameController = TextEditingController(text: 'Мой дизайн');
    bool chroma = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Название дизайна', style: TextStyle(fontSize: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название'),
                autofocus: true,
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                value: chroma,
                onChanged: (v) =>
                    setDialogState(() => chroma = v ?? false),
                title: const Text('Убрать белый фон',
                    style: TextStyle(fontSize: 15)),
                subtitle: const Text(
                  'для JPG/PNG без прозрачности',
                  style: TextStyle(fontSize: 12),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
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
      ),
    );

    if (ok == true && nameController.text.trim().isNotEmpty) {
      // Chroma-key: белый фон убирается ОДИН РАЗ при импорте
      File sourceFile = File(photo.path);
      if (chroma) {
        final bytes = await ChromaKey.removeWhiteBackground(
            await File(photo.path).readAsBytes());
        final tmp =
            File('${(await getTemporaryDirectory()).path}/chroma_tmp.png');
        await tmp.writeAsBytes(bytes);
        sourceFile = tmp;
      }
      final savedPath =
          await DatabaseService.savePhoto(sourceFile, 'pattern');
      await DatabaseService.addMyDesign(MyDesign(
        id: const Uuid().v4(),
        name: nameController.text.trim(),
        type: MyDesignType.image,
        imagePath: savedPath,
        createdAt: DateTime.now(),
      ));
      setState(() {
        _myDesigns = DatabaseService.getMyDesigns();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chroma
                ? 'Дизайн сохранён (белый фон убран)'
                : 'Дизайн сохранён'),
            backgroundColor: Colors.green,
          ),
        );
      }
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

  /// Пикер узора возвращает PatternPickResult — узор И/ИЛИ картинка-узор.
  /// Обработка обоих вариантов: векторный узор и/или картинка (в т.ч. сброс).
  Future<void> _openPatternPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatternPickerScreen(
          currentPattern: _design.pattern,
          previewColor: _design.color?.color ?? Colors.pink,
          currentImagePath: _design.patternPath,
        ),
      ),
    );

    if (result != null && result is PatternPickResult) {
      setState(() {
        _design = SelectedDesign(
          color: _design.color,
          material: _design.material,
          shape: _design.shape,
          density: _design.density,
          brightness: _design.brightness,
          pattern: result.pattern,
          patternPath: result.imagePath,
          patternName: result.imageName,
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
                      subtitle: _design.patternName != null
                          ? '🖼 ${_design.patternName}'
                          : NailPattern.getTypeName(_design.pattern.type),
                      color: _design.patternName != null
                          ? Colors.pink[100]!
                          : (_design.pattern.isNone
                              ? Colors.grey[300]!
                              : _design.pattern.color),
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

  /// Превью рецепта — WYSIWYG: тот же Nail3DRenderer, что и в примерке.
  Widget _buildRecipePreview(MyDesign d) {
    final color = _findColor(d.colorId);
    final material = _findMaterial(d.materialId);

    // Legacy-заглушка: цвет не найден
    if (color == null) {
      return Container(color: Colors.grey);
    }

    final design = SelectedDesign(
      color: color,
      material: material,
      shape: d.shape,
      density: d.density,
      brightness: d.brightness,
      pattern: d.pattern,
      edgeDarken: d.edgeDarken,
      highlightIntensity: d.highlightIntensity,
      shadowIntensity: d.shadowIntensity,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFAE9DD),
                Color(0xFFF2D9C8),
              ],
            ),
          ),
          child: Nail3DRenderer(
            design: design,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            showCuticle: false,
          ),
        );
      },
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