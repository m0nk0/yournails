import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/nail_session.dart';

class TemplateScreen extends StatefulWidget {
  final NailSession session;

  const TemplateScreen({super.key, required this.session});

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final TextEditingController _captionController = TextEditingController(text: 'Маникюр');
  final TextEditingController _masterNameController = TextEditingController(text: '@your_nails');

  Color _backgroundColor = const Color(0xFFF5E6E8);
  bool _isProcessing = false;

  // Варианты фонов
  final List<Color> _backgroundOptions = [
    const Color(0xFFF5E6E8), // Нежно-розовый
    const Color(0xFFE8F0F5), // Голубой
    const Color(0xFFF5F0E8), // Бежевый
    const Color(0xFFE8F5E9), // Мятный
    const Color(0xFFF3E5F5), // Лавандовый
    Colors.white,
  ];

  /// Рендеринг шаблона в изображение и шаринг
  Future<void> _saveAndShare() async {
    setState(() => _isProcessing = true);

    try {
      // Получаем RenderRepaintBoundary
      final boundary = _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Рендерим виджет в изображение (pixelRatio 3.0 = высокое качество)
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Сохраняем во временную папку
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/template_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      // Шарим в соцсети
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${_captionController.text} | ${_masterNameController.text}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при создании шаблона: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Шаблон для соцсетей', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Превью шаблона
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: _buildTemplate(),
                ),
              ),
            ),
          ),

          // Панель управления
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Поле для подписи
                TextField(
                  controller: _captionController,
                  decoration: const InputDecoration(
                    labelText: 'Подпись',
                    hintText: 'Маникюр',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 18),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Поле для имени мастера
                TextField(
                  controller: _masterNameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя мастера / ник',
                    hintText: '@your_nails',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 18),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Выбор цвета фона
                Row(
                  children: [
                    const Text(
                      'Фон:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _backgroundOptions.map((color) {
                          final isSelected = _backgroundColor == color;
                          return GestureDetector(
                            onTap: () => setState(() => _backgroundColor = color),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.pink : Colors.grey[300]!,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Кнопка сохранить и поделиться
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _saveAndShare,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share),
                    label: Text(
                      _isProcessing ? 'Создание...' : 'Сохранить и поделиться',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Виджет шаблона (рендерится в изображение)
  Widget _buildTemplate() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок
          Text(
            _captionController.text.isEmpty ? 'Маникюр' : _captionController.text,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Коллаж до/после
          Row(
            children: [
              // Фото "до"
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'До',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.session.hasBefore
                            ? Image.file(
                                File(widget.session.beforePhotoPath!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.photo, color: Colors.grey),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Фото "после"
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'После',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.session.hasAfter
                            ? Image.file(
                                File(widget.session.afterPhotoPath!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.photo, color: Colors.grey),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Имя мастера
          Text(
            _masterNameController.text.isEmpty ? '@your_nails' : _masterNameController.text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}