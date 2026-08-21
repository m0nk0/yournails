import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/nail_session.dart';
import 'template_screen.dart';

class PhotoViewScreen extends StatelessWidget {
  final File imageFile;
  final String title;
  final NailSession? session;

  const PhotoViewScreen({
    super.key,
    required this.imageFile,
    required this.title,
    this.session,
  });

  /// Поделиться фото в соцсети
  Future<void> _sharePhoto(BuildContext context) async {
    try {
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: title,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при отправке: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Обработать фото → открыть шаблон
  void _processPhoto(BuildContext context) {
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет данных визита для создания шаблона'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateScreen(session: session!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 20),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Фото на весь экран
          Expanded(
            child: Center(
              child: InteractiveViewer(
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Кнопки внизу
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Кнопка "Обработать"
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _processPhoto(context),
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text(
                      'Обработать',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Кнопка "Поделиться"
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sharePhoto(context),
                    icon: const Icon(Icons.share),
                    label: const Text(
                      'Поделиться',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
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
}