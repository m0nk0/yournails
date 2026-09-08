import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../library/unified_library_service.dart';
import '../services/tryon_session_service.dart';
import 'edit_screen.dart';

/// Единая точка входа в примерку с главного экрана.
/// Логика: есть живая сессия → предложить продолжить; иначе → выбор фото.
class TryOnEntry {
  static Future<void> launch(BuildContext context) async {
    // Прогреваем кэш библиотеки, чтобы ID из сессии резолвились синхронно
    await UnifiedLibraryService.getFullLibrary();

    final session = await TryOnSessionService.load();
    if (session != null) {
      if (await File(session.photoPath).exists()) {
        if (!context.mounted) return;
        final cont = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Продолжить примерку?',
                style: TextStyle(fontSize: 20)),
            content: Text(
              'Сохранена незаконченная примерка от ${_formatDate(session.savedAt)}.\n\n'
              'Продолжить с того же места или начать заново?',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Начать заново'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Продолжить'),
              ),
            ],
          ),
        );
        if (cont == true && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditScreen(
                imageFile: File(session.photoPath),
                restored: session,
              ),
            ),
          );
          return;
        }
      } else {
        // Фото больше не существует — сессия мертва
        await TryOnSessionService.clear();
      }
    }

    if (!context.mounted) return;
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новая примерка', style: TextStyle(fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, size: 28),
              title: const Text('Из галереи', style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, size: 28),
              title: const Text('Сделать фото', style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final XFile? photo =
        await ImagePicker().pickImage(source: source, imageQuality: 90);
    if (photo == null) return;

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditScreen(imageFile: File(photo.path)),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }
}