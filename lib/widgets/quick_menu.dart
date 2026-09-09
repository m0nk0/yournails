import 'package:flutter/material.dart';

import '../screens/crm_screen.dart';
import '../screens/my_designs_screen.dart';

/// Бургер-меню быстрых переходов: Клиенты / Мои дизайны / На главный.
/// Используется на экране примерки и экране результата.
/// Отдельная кнопка «домой» не нужна — она живёт внутри меню.
class QuickMenuButton extends StatelessWidget {
  const QuickMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Меню',
      iconSize: 36,
      padding: const EdgeInsets.all(10),
      icon: const Icon(Icons.menu, size: 34),
      onSelected: (value) => _onSelected(context, value),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'crm',
          height: 56,
          child: Row(
            children: [
              Icon(Icons.people, size: 26),
              SizedBox(width: 12),
              Text('Клиенты', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'designs',
          height: 56,
          child: Row(
            children: [
              Icon(Icons.bookmarks, size: 26),
              SizedBox(width: 12),
              Text('Мои дизайны', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'home',
          height: 56,
          child: Row(
            children: [
              Icon(Icons.home, size: 26),
              SizedBox(width: 12),
              Text('На главный', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ],
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