import 'package:flutter/material.dart';
import '../models/nail_color.dart';

/// Трендовая палитра — набор из 5-6 гармонирующих цветов
/// с номером и подзаголовком (без упоминания брендов).
class TrendPalette {
  final String id;
  final String name;       // «Палитра №1»
  final String subtitle;   // «Молочный миндаль»
  final List<NailColor> colors;

  const TrendPalette({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.colors,
  });
}

/// Сервис трендовых палитр.
/// Сейчас хардкод — в будущем можно подгружать из БД/JSON/удалённого API.
class TrendPalettesService {
  static List<TrendPalette> getPalettes() {
    return [
      TrendPalette(
        id: 'trend_1',
        name: 'Палитра №1',
        subtitle: 'Молочный миндаль',
        colors: [
          NailColor(id: 't1_c1', name: 'Молоко',       color: Color(0xFFF5F0E8), group: 'nude'),
          NailColor(id: 't1_c2', name: 'Айвори',       color: Color(0xFFFAF0E6), group: 'nude'),
          NailColor(id: 't1_c3', name: 'Миндаль',      color: Color(0xFFEED9C4), group: 'nude'),
          NailColor(id: 't1_c4', name: 'Бежевый нюд',  color: Color(0xFFE8D5C4), group: 'nude'),
          NailColor(id: 't1_c5', name: 'Капучино',     color: Color(0xFFC9A384), group: 'nude'),
          NailColor(id: 't1_c6', name: 'Карамель',     color: Color(0xFFC68E4C), group: 'nude'),
        ],
      ),

      TrendPalette(
        id: 'trend_2',
        name: 'Палитра №2',
        subtitle: 'Тёмный шоколад',
        colors: [
          NailColor(id: 't2_c1', name: 'Кофе',        color: Color(0xFF6F4E37), group: 'dark'),
          NailColor(id: 't2_c2', name: 'Эспрессо',    color: Color(0xFF4E342E), group: 'dark'),
          NailColor(id: 't2_c3', name: 'Шоколад',     color: Color(0xFF7B3F00), group: 'dark'),
          NailColor(id: 't2_c4', name: 'Бордо',       color: Color(0xFF8E2323), group: 'red'),
          NailColor(id: 't2_c5', name: 'Марсала',     color: Color(0xFF955251), group: 'red'),
          NailColor(id: 't2_c6', name: 'Графит',      color: Color(0xFF424242), group: 'dark'),
        ],
      ),

      TrendPalette(
        id: 'trend_3',
        name: 'Палитра №3',
        subtitle: 'Розовый закат',
        colors: [
          NailColor(id: 't3_c1', name: 'Пудровый',    color: Color(0xFFFADADD), group: 'pink'),
          NailColor(id: 't3_c2', name: 'Нежный',      color: Color(0xFFF8BBD0), group: 'pink'),
          NailColor(id: 't3_c3', name: 'Пыльная роза',color: Color(0xFFD4A5A5), group: 'pink'),
          NailColor(id: 't3_c4', name: 'Коралл',      color: Color(0xFFFF7F50), group: 'pink'),
          NailColor(id: 't3_c5', name: 'Персик',      color: Color(0xFFFFCBA4), group: 'yellow'),
          NailColor(id: 't3_c6', name: 'Фуксия',      color: Color(0xFFE91E63), group: 'pink'),
        ],
      ),

      TrendPalette(
        id: 'trend_4',
        name: 'Палитра №4',
        subtitle: 'Лавандовый вечер',
        colors: [
          NailColor(id: 't4_c1', name: 'Лаванда',     color: Color(0xFFB39DDB), group: 'purple'),
          NailColor(id: 't4_c2', name: 'Сирень',      color: Color(0xFFC8A2C8), group: 'purple'),
          NailColor(id: 't4_c3', name: 'Лиловый',     color: Color(0xFFB784A7), group: 'purple'),
          NailColor(id: 't4_c4', name: 'Фиалка',      color: Color(0xFF9575CD), group: 'purple'),
          NailColor(id: 't4_c5', name: 'Слива',       color: Color(0xFF6A1B9A), group: 'purple'),
          NailColor(id: 't4_c6', name: 'Пурпур',      color: Color(0xFF4A148C), group: 'purple'),
        ],
      ),

      TrendPalette(
        id: 'trend_5',
        name: 'Палитра №5',
        subtitle: 'Лесной мох',
        colors: [
          NailColor(id: 't5_c1', name: 'Шалфей',       color: Color(0xFFB2AC88), group: 'green'),
          NailColor(id: 't5_c2', name: 'Мята',         color: Color(0xFF80CBC4), group: 'green'),
          NailColor(id: 't5_c3', name: 'Фисташка',     color: Color(0xFF93C572), group: 'green'),
          NailColor(id: 't5_c4', name: 'Олива',        color: Color(0xFF808000), group: 'green'),
          NailColor(id: 't5_c5', name: 'Изумруд',      color: Color(0xFF2E7D32), group: 'green'),
          NailColor(id: 't5_c6', name: 'Бутылочный',   color: Color(0xFF1B4D3E), group: 'green'),
        ],
      ),
    ];
  }
}