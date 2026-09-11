// lib/screens/home_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'camera_screen.dart';
import 'edit_screen.dart';
import 'my_designs_screen.dart';
import 'manage_masters_screen.dart';
import 'crm_screen.dart';
import '../services/tryon_session_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Тап по «Примерке»: если есть сохранённая сессия — предлагаем
  /// продолжить её или начать новую. Иначе — сразу камера.
  Future<void> _openTryOn(BuildContext context) async {
    final session = await TryOnSessionService.load();

    // Сессии нет — обычный вход через камеру
    if (session == null) {
      _pushCamera(context);
      return;
    }

    // Файл фото мог исчезнуть (чистка системы) — считаем сессию битой
    final file = File(session.photoPath);
    if (!await file.exists()) {
      await TryOnSessionService.clear();
      _pushCamera(context);
      return;
    }

    final months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    final d = session.savedAt;
    final when = '${d.day} ${months[d.month - 1]}, '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    final continueSession = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Продолжить примерку?',
            style: TextStyle(fontSize: 20)),
        content: Text(
          'Есть сохранённая примерка от $when.\n\n'
          'Продолжить её или начать новую?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Начать новую', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Продолжить', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    // Закрыл диалог без выбора — ничего не делаем
    if (continueSession == null) return;

    if (continueSession) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditScreen(imageFile: file, restored: session),
          ),
        );
      }
    } else {
      await TryOnSessionService.clear();
      if (context.mounted) _pushCamera(context);
    }
  }

  void _pushCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Твои Ноготочки'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageMastersScreen()),
            ),
            icon: const Icon(Icons.people_alt, size: 20),
            label: const Text(
              'Мастера',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxHeight < 760;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Column(
                  mainAxisAlignment:
                      isSmall ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    // Логотип
                    SvgPicture.asset(
                      'assets/logo.svg',
                      width: isSmall ? 120 : 150,
                      height: isSmall ? 120 : 150,
                    ),
                    SizedBox(height: isSmall ? 10 : 14),
                    const Text(
                      'Твои Ноготочки',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Цифровая студия nail-арта',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, color: Colors.grey[600]),
                    ),
                    SizedBox(height: isSmall ? 24 : 34),

                    _buildBigButton(
                      title: 'Примерка',
                      icon: Icons.camera_alt,
                      color: Colors.pink,
                      onTap: () => _openTryOn(context),
                    ),
                    const SizedBox(height: 14),

                    _buildBigButton(
                      title: 'Мои клиенты',
                      subtitle: 'клиенты • напоминания • финансы',
                      icon: Icons.business_center,
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CrmScreen()),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildBigButton(
                      title: 'Мои дизайны',
                      icon: Icons.bookmark,
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyDesignsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Большая яркая кнопка одинаковой формы и размера
  Widget _buildBigButton({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: subtitle == null ? 82 : 92,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 38, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 30),
          ],
        ),
      ),
    );
  }
}