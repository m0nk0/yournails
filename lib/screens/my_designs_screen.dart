import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/my_design.dart';
import '../models/nail_color.dart';
import '../models/nail_material.dart';
import '../models/nail_shape.dart';
import '../services/database_service.dart';
import '../services/design_sets_service.dart';
import '../widgets/home_app_bar.dart';

/// Экран-витрина коллекции дизайнов мастера
class MyDesignsScreen extends StatefulWidget {
  const MyDesignsScreen({super.key});

  @override
  State<MyDesignsScreen> createState() => _MyDesignsScreenState();
}

class _MyDesignsScreenState extends State<MyDesignsScreen> {
  List<MyDesign> _designs = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadDesigns();
  }

  void _loadDesigns() {
    setState(() {
      _designs = DatabaseService.getMyDesigns();
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

  /// Загрузить PNG/фото
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
            child: const Text('Отмена', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
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
      _loadDesigns();
    }
  }

  /// Удалить дизайн
  Future<void> _deleteDesign(MyDesign d) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить дизайн?', style: TextStyle(fontSize: 20)),
        content: Text(
          '"${d.name}" будет удалён из коллекции.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.deleteMyDesign(d.id);
      _loadDesigns();
    }
  }

  /// Показать детали дизайна
  void _showDetails(MyDesign d) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(d.name, style: const TextStyle(fontSize: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              height: 300,
              child: d.isImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(d.imagePath!),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _buildRecipePreview(d),
            ),
            const SizedBox(height: 16),
            if (d.isRecipe) ...[
              _detailRow('Цвет', _findColor(d.colorId)?.name ?? '—'),
              _detailRow('Материал', _findMaterial(d.materialId)?.name ?? '—'),
              _detailRow('Форма', NailShapeHelper.getName(d.shape)),
              _detailRow('Слои', '${d.density.toInt()}'),
            ] else
              const Text(
                'Загруженная картинка',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 17, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Превью рецепта — ноготь на светлой коже с тонкой рамкой
  Widget _buildRecipePreview(MyDesign d) {
    final color = _findColor(d.colorId)?.color ?? Colors.grey;
    final material = _findMaterial(d.materialId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // ИСПРАВЛЕНО: ноготь шире (пропорция ~0.72 как у настоящего)
        final nailW = w * 0.72;
        final nailH = h * 0.78;
        final radius = NailShapeHelper.getBorderRadius(d.shape, nailW, nailH);

        return Container(
          decoration: BoxDecoration(
            // ИСПРАВЛЕНО: бледная кожа
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFAE9DD),
                Color(0xFFF2D9C8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Container(
              width: nailW,
              height: nailH,
              decoration: BoxDecoration(
                color: color,
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: (material?.hasGloss ?? false)
                  ? ClipRRect(
                      borderRadius: radius,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(material!.glossIntensity * 0.30),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5],
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Адаптивно: планшет 3 колонки, смартфон 2
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
            appBar: const HomeAppBar(
        title: Text('Мои дизайны', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.deepPurple,
      ),
      body: _designs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'Коллекция пуста',
                    style: TextStyle(fontSize: 24, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Сохраняйте удачные дизайны\nи загружайте картинки из интернета',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: _designs.length,
              itemBuilder: (context, index) {
                final d = _designs[index];
                return GestureDetector(
                  onTap: () => _showDetails(d),
                  onLongPress: () => _deleteDesign(d),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 0.75,
                        child: d.isImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.9),
                                      width: 2,
                                    ),
                                  ),
                                  child: Image.file(
                                    File(d.imagePath!),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : _buildRecipePreview(d),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            d.isRecipe ? Icons.bookmark : Icons.image,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              d.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadImage,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}