// lib/constants/master_icons.dart

import 'package:flutter/material.dart';

/// Набор готовых иконок для мастеров
class MasterIcons {
  static const List<Map<String, dynamic>> availableIcons = [
    {'name': 'auto_awesome', 'icon': Icons.auto_awesome, 'label': 'Магия'},
    {'name': 'spa', 'icon': Icons.spa, 'label': 'Спа'},
    {'name': 'favorite', 'icon': Icons.favorite, 'label': 'Сердце'},
    {'name': 'diamond', 'icon': Icons.diamond, 'label': 'Бриллиант'},
    {'name': 'palette', 'icon': Icons.palette, 'label': 'Палитра'},
    {'name': 'brush', 'icon': Icons.brush, 'label': 'Кисть'},
    {'name': 'star', 'icon': Icons.star, 'label': 'Звезда'},
    {'name': 'emoji_events', 'icon': Icons.emoji_events, 'label': 'Трофей'},
    {'name': 'local_florist', 'icon': Icons.local_florist, 'label': 'Цветок'},
    {'name': 'pets', 'icon': Icons.pets, 'label': 'Лапки'},
    {'name': 'cake', 'icon': Icons.cake, 'label': 'Торт'},
    {'name': 'self_improvement', 'icon': Icons.self_improvement, 'label': 'Медитация'},
    {'name': 'color_lens', 'icon': Icons.color_lens, 'label': 'Краски'},
    {'name': 'handshake', 'icon': Icons.handshake, 'label': 'Рукопожатие'},
    {'name': 'volunteer_activism', 'icon': Icons.volunteer_activism, 'label': 'Волонтёр'},
  ];

  /// Получить иконку по имени
  static IconData getIconByName(String name) {
    final found = availableIcons.firstWhere(
      (item) => item['name'] == name,
      orElse: () => availableIcons.first,
    );
    return found['icon'] as IconData;
  }
}