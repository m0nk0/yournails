import 'package:flutter/material.dart';

import '../screens/crm_screen.dart';
import '../screens/my_designs_screen.dart';
import '../theme/app_theme.dart';

/// Бургер-меню быстрых переходов: Клиенты / Мои дизайны / На главный.
/// Используется на экране примерки и экране результата.
/// Отдельная кнопка «домой» не нужна — она живёт внутри меню.
///
/// ВАЖНО: цвета иконок и текста заданы ЯВНО. Всплывающее меню
/// наследует IconTheme от контекста AppBar (там иконки белые),
/// из-за чего без явного цвета иконки сливались с белым фоном меню.
class QuickMenuButton extends StatelessWidget {
  const QuickMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Меню',
      iconSize: 36,
      padding: const EdgeInsets.all(10),
      icon: const Icon(Icons.menu, size: 34),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      offset: const Offset(0, 48),
      onSelected: (value) => _onSelected(context, value),
      itemBuilder: (_) => [
        _menuItem('crm', Icons.people_alt, 'Клиенты'),
        _menuItem('designs', Icons.bookmarks, 'Мои дизайны'),
        _menuItem('home', Icons.home_outlined, 'На главный'),
      ],
    );
  }

  /// Пункт меню: винная иконка + тёмный текст на белом — видно всегда
  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      height: 52,
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.wine),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSelected(BuildContext context, String value) async {
    switch (value) {
      case 'crm':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CrmScreen()),
        );
        break;
      case 'designs':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyDesignsScreen()),
        );
        break;
      case 'home':
        // Домой = выталкиваем всё до главного экрана.
        // Примерка при этом сохранит сессию (dispose → TryOnSession).
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
    }
  }
}