import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/my_design.dart';
import '../models/nail_pattern.dart';
import '../models/nail_shape.dart';
import '../services/database_service.dart';
import '../utils/top_message.dart';
import '../widgets/nail_pattern_layer.dart';

/// Результат выбора рисунка: векторный узор ИЛИ своя картинка-узор.
class PatternPickResult {
  final NailPattern pattern;
  final String? imagePath;
  final String? imageName;

  const PatternPickResult({
    required this.pattern,
    this.imagePath,
    this.imageName,
  });
}

/// Экран выбора рисунка (узора) и его цвета.
/// Раздел «Мои картинки»: свои PNG/фото из общей базы дизайнов (type=image).
class PatternPickerScreen extends StatefulWidget {
  final NailPattern currentPattern;
  final Color previewColor;

  /// Текущая картинка-узор (если есть), чтобы подсветить выбор
  final String? currentImagePath;

  const PatternPickerScreen({
    super.key,
    required this.currentPattern,
    required this.previewColor,
    this.currentImagePath,
  });

  @override
  State<PatternPickerScreen> createState() => _PatternPickerScreenState();
}

class _PatternPickerScreenState extends State<PatternPickerScreen> {
  late NailPatternType _type;
  late Color _color;
  String? _imagePath;
  String? _imageName;
  List<MyDesign> _myImages = [];
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  static const List<Color> _patternColors = [
    Colors.white,
    Colors.black,
    Color(0xFFFFD700), // Золото
    Color(0xFFC0C0C0), // Серебро
    Color(0xFFF48FB1), // Розовый
    Color(0xFFE53935), // Красный
    Color(0xFF81D4FA), // Голубой
    Color(0xFFB39DDB), // Фиолетовый
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.currentPattern.type;
    _color = widget.currentPattern.color;
    _imagePath = widget.currentImagePath;
    _loadImages();
  }

  void _loadImages() {
    setState(() {
      _myImages =
          DatabaseService.getMyDesigns().where((d) => d.isImage).toList();
      // Подсветка имени, если картинка уже выбрана
      if (_imagePath != null) {
        for (final d in _myImages) {
          if (d.imagePath == _imagePath) _imageName = d.name;
        }
      }
    });
  }

  // ============ ЗАГРУЗКА СВОЕЙ КАРТИНКИ ============

  Future<void> _uploadImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Своя картинка', style: TextStyle(fontSize: 20)),
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

    setState(() => _uploading = true);
    try {
      final XFile? photo =
          await _picker.pickImage(source: source, imageQuality: 90);
      if (photo == null) return;

      final nameController = TextEditingController(text: 'Моя картинка');
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Название', style: TextStyle(fontSize: 20)),
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
        final savedPath =
            await DatabaseService.savePhoto(File(photo.path), 'pattern');
        await DatabaseService.addMyDesign(MyDesign(
          id: const Uuid().v4(),
          name: nameController.text.trim(),
          type: MyDesignType.image,
          imagePath: savedPath,
          createdAt: DateTime.now(),
        ));
        _loadImages();
        // Сразу выбираем загруженную картинку
        setState(() {
          _imagePath = savedPath;
          _imageName = nameController.text.trim();
        });
        if (mounted) {
          TopMessage.show(context, 'Картинка добавлена и выбрана',
              color: Colors.green);
        }
      }
    } catch (e) {
      if (mounted) {
        TopMessage.show(context, 'Ошибка загрузки: $e', color: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteImage(MyDesign d) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить картинку?', style: TextStyle(fontSize: 20)),
        content: Text('"${d.name}" будет удалена из библиотеки.'),
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
      if (_imagePath == d.imagePath) {
        setState(() {
          _imagePath = null;
          _imageName = null;
        });
      }
      _loadImages();
    }
  }

  // ============ ПРИМЕНЕНИЕ ============

  void _apply() {
    if (_imagePath != null) {
      // Картинка заменяет векторный узор
      Navigator.pop(
        context,
        PatternPickResult(
          pattern: NailPattern(type: NailPatternType.none, color: _color),
          imagePath: _imagePath,
          imageName: _imageName,
        ),
      );
    } else {
      Navigator.pop(
        context,
        PatternPickResult(pattern: NailPattern(type: _type, color: _color)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рисунок', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Большое превью
          Center(
            child: SizedBox(
              width: 140,
              height: 180,
              child: ClipRRect(
                borderRadius:
                    NailShapeHelper.getBorderRadius(NailShape.oval, 140, 180),
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: Container(color: widget.previewColor)),
                    if (_imagePath != null)
                      Positioned.fill(
                        child: Image.file(
                          File(_imagePath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Positioned.fill(
                        child: NailPatternLayer(
                          pattern: NailPattern(type: _type, color: _color),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _imagePath != null
                  ? 'Картинка: $_imageName'
                  : 'Узор: ${NailPattern.getTypeName(_type)}',
              style: TextStyle(
                fontSize: 13,
                color: _imagePath != null ? Colors.pink : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // === МОИ КАРТИНКИ ===
          const Text(
            'Мои картинки',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Тап — выбрать • Долгое нажатие — удалить',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Плитка «+»
                GestureDetector(
                  onTap: _uploading ? null : _uploadImage,
                  child: Container(
                    width: 76,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      border: Border.all(color: Colors.pink, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _uploading
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.pink),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  color: Colors.pink, size: 30),
                              SizedBox(height: 2),
                              Text(
                                'Добавить',
                                style: TextStyle(
                                  color: Colors.pink,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                // Свои картинки
                ..._myImages.map((d) {
                  final isSelected = _imagePath == d.imagePath;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _imagePath = d.imagePath;
                      _imageName = d.name;
                    }),
                    onLongPress: () => _deleteImage(d),
                    child: Container(
                      width: 76,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.pink : Colors.grey[300]!,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(d.imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Узор',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Выбор узора снимает картинку',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),

          // Сетка узоров с живым превью
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: NailPatternType.values.length,
            itemBuilder: (context, index) {
              final type = NailPatternType.values[index];
              final isSelected = _imagePath == null && _type == type;

              return GestureDetector(
                onTap: () => setState(() {
                  _type = type;
                  _imagePath = null; // узор снимает картинку
                  _imageName = null;
                }),
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
                    child: Stack(
                      children: [
                        Positioned.fill(
                            child: Container(color: widget.previewColor)),
                        Positioned.fill(
                          child: NailPatternLayer(
                            pattern: NailPattern(type: type, color: _color),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.85),
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              NailPattern.getTypeName(type),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          const Text(
            'Цвет узора',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _patternColors.map((c) {
              final isSelected = _color.value == c.value;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.pink : Colors.grey[400]!,
                      width: isSelected ? 4 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Применить', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}