import 'package:flutter/material.dart';

import '../models/nail_color.dart';
import '../models/nail_material.dart';

/// Архив старых цветов и материалов (до Единой Библиотеки).
/// НЕ является сервисом — это чистые данные для резолва старых ID,
/// которые хранятся в сохранённых рецептах («Мои дизайны») и сессиях.
///
/// Когда старые рецепты будут мигрированы или объявлены неактуальными,
/// этот файл удаляется вместе с fallback-ветками в UnifiedLibraryService.
class LegacyCatalog {
  LegacyCatalog._();

  /// Старые цвета (ID вида 'red_wine', 'gray_graphite'…)
  static final List<NailColor> colors = [
    // ===== КРАСНЫЕ =====
    NailColor(id: 'red_classic', name: 'Классический', color: const Color(0xFFE53935), group: 'red'),
    NailColor(id: 'red_scarlet', name: 'Алый', color: const Color(0xFFFF2400), group: 'red'),
    NailColor(id: 'red_cherry', name: 'Вишнёвый', color: const Color(0xFFB24A4A), group: 'red'),
    NailColor(id: 'red_burgundy', name: 'Бордовый', color: const Color(0xFF8E2323), group: 'red'),
    NailColor(id: 'red_wine', name: 'Винный', color: const Color(0xFF722F37), group: 'red'),
    NailColor(id: 'red_marsala', name: 'Марсала', color: const Color(0xFF955251), group: 'red'),
    NailColor(id: 'red_terracotta', name: 'Терракот', color: const Color(0xFFC76B4A), group: 'red'),

    // ===== РОЗОВЫЕ =====
    NailColor(id: 'pink_gentle', name: 'Нежный', color: const Color(0xFFF8BBD0), group: 'pink'),
    NailColor(id: 'pink_powder', name: 'Пудровый', color: const Color(0xFFFADADD), group: 'pink'),
    NailColor(id: 'pink_dusty', name: 'Пыльная роза', color: const Color(0xFFD4A5A5), group: 'pink'),
    NailColor(id: 'pink_baby', name: 'Бэби-пинк', color: const Color(0xFFFBCFE8), group: 'pink'),
    NailColor(id: 'pink_fuchsia', name: 'Фуксия', color: const Color(0xFFE91E63), group: 'pink'),
    NailColor(id: 'pink_raspberry', name: 'Малина', color: const Color(0xFFE30B5C), group: 'pink'),
    NailColor(id: 'pink_coral', name: 'Коралл', color: const Color(0xFFFF7F50), group: 'pink'),

    // ===== НЮД И БЕЛЫЕ =====
    NailColor(id: 'nude_milk', name: 'Молочный', color: const Color(0xFFF5F0E8), group: 'nude'),
    NailColor(id: 'nude_ivory', name: 'Айвори', color: const Color(0xFFFAF0E6), group: 'nude'),
    NailColor(id: 'nude_beige', name: 'Бежевый', color: const Color(0xFFE8D5C4), group: 'nude'),
    NailColor(id: 'nude_pink', name: 'Розовый беж', color: const Color(0xFFE8C4C4), group: 'nude'),
    NailColor(id: 'nude_cappuccino', name: 'Капучино', color: const Color(0xFFC9A384), group: 'nude'),
    NailColor(id: 'nude_caramel', name: 'Карамель', color: const Color(0xFFC68E4C), group: 'nude'),
    NailColor(id: 'white_pure', name: 'Белый', color: const Color(0xFFFFFFFF), group: 'nude'),
    NailColor(id: 'white_pearl', name: 'Жемчужный', color: const Color(0xFFFDEEF4), group: 'nude'),

    // ===== ФИОЛЕТОВЫЕ =====
    NailColor(id: 'purple_lavender', name: 'Лавандовый', color: const Color(0xFFB39DDB), group: 'purple'),
    NailColor(id: 'purple_lilac', name: 'Сиреневый', color: const Color(0xFFC8A2C8), group: 'purple'),
    NailColor(id: 'purple_lilac_2', name: 'Лиловый', color: const Color(0xFFB784A7), group: 'purple'),
    NailColor(id: 'purple_violet', name: 'Фиалка', color: const Color(0xFF9575CD), group: 'purple'),
    NailColor(id: 'purple_plum', name: 'Сливовый', color: const Color(0xFF6A1B9A), group: 'purple'),
    NailColor(id: 'purple_royal', name: 'Пурпур', color: const Color(0xFF4A148C), group: 'purple'),

    // ===== СИНИЕ =====
    NailColor(id: 'blue_baby', name: 'Голубой', color: const Color(0xFF81D4FA), group: 'blue'),
    NailColor(id: 'blue_azure', name: 'Лазурь', color: const Color(0xFF007FFF), group: 'blue'),
    NailColor(id: 'blue_cobalt', name: 'Кобальт', color: const Color(0xFF0047AB), group: 'blue'),
    NailColor(id: 'blue_denim', name: 'Деним', color: const Color(0xFF6F8FAF), group: 'blue'),
    NailColor(id: 'blue_navy', name: 'Navy', color: const Color(0xFF1A237E), group: 'blue'),
    NailColor(id: 'blue_turquoise', name: 'Бирюзовый', color: const Color(0xFF26C6DA), group: 'blue'),
    NailColor(id: 'blue_teal', name: 'Мята', color: const Color(0xFF4DB6AC), group: 'blue'),

    // ===== ЗЕЛЁНЫЕ =====
    NailColor(id: 'green_sage', name: 'Шалфей', color: const Color(0xFFB2AC88), group: 'green'),
    NailColor(id: 'green_mint', name: 'Мятный', color: const Color(0xFF80CBC4), group: 'green'),
    NailColor(id: 'green_pistachio', name: 'Фисташка', color: const Color(0xFF93C572), group: 'green'),
    NailColor(id: 'green_olive', name: 'Оливковый', color: const Color(0xFF808000), group: 'green'),
    NailColor(id: 'green_emerald', name: 'Изумрудный', color: const Color(0xFF2E7D32), group: 'green'),
    NailColor(id: 'green_bottle', name: 'Бутылочный', color: const Color(0xFF1B4D3E), group: 'green'),

    // ===== ЖЁЛТО-ОРАНЖЕВЫЕ =====
    NailColor(id: 'yellow_lemon', name: 'Лимонный', color: const Color(0xFFFFF176), group: 'yellow'),
    NailColor(id: 'yellow_sun', name: 'Солнечный', color: const Color(0xFFFFEB3B), group: 'yellow'),
    NailColor(id: 'yellow_mustard', name: 'Горчица', color: const Color(0xFFD4AF37), group: 'yellow'),
    NailColor(id: 'orange_peach', name: 'Персик', color: const Color(0xFFFFCBA4), group: 'yellow'),
    NailColor(id: 'orange_apricot', name: 'Абрикос', color: const Color(0xFFFBCEB1), group: 'yellow'),
    NailColor(id: 'orange_bright', name: 'Апельсин', color: const Color(0xFFFF7F00), group: 'yellow'),

    // ===== СЕРЫЕ И ТЁМНЫЕ =====
    NailColor(id: 'gray_light', name: 'Светло-серый', color: const Color(0xFFBDBDBD), group: 'dark'),
    NailColor(id: 'gray_asphalt', name: 'Мокрый асфальт', color: const Color(0xFF616161), group: 'dark'),
    NailColor(id: 'gray_graphite', name: 'Графит', color: const Color(0xFF424242), group: 'dark'),
    NailColor(id: 'black_gloss', name: 'Чёрный глянец', color: const Color(0xFF212121), group: 'dark'),
    NailColor(id: 'brown_coffee', name: 'Кофе', color: const Color(0xFF6F4E37), group: 'dark'),
    NailColor(id: 'brown_chocolate', name: 'Шоколад', color: const Color(0xFF7B3F00), group: 'dark'),
  ];

  /// Старые материалы (ID вида 'gel_polish', 'bio_gel'…)
  static final List<NailMaterial> materials = [
    NailMaterial(
      id: 'gel_polish',
      name: 'Гель-лак',
      description: 'Глянцевый, насыщенный, держится 2-3 недели',
      opacity: 1.0,
      saturation: 1.0,
      hasGloss: true,
      glossIntensity: 0.8,
    ),
    NailMaterial(
      id: 'gel',
      name: 'Гель',
      description: 'Плотный, для наращивания, лёгкий глянец',
      opacity: 1.0,
      saturation: 1.0,
      hasGloss: true,
      glossIntensity: 0.5,
    ),
    NailMaterial(
      id: 'acrylic',
      name: 'Акрил',
      description: 'Матовый, прочный, приглушенный цвет',
      opacity: 1.0,
      saturation: 0.7,
      hasGloss: false,
      glossIntensity: 0.0,
    ),
    NailMaterial(
      id: 'bio_gel',
      name: 'Биогель',
      description: 'Полупрозрачный, щадящий, мягкий',
      opacity: 0.65,
      saturation: 0.9,
      hasGloss: true,
      glossIntensity: 0.4,
    ),
    NailMaterial(
      id: 'regular_polish',
      name: 'Обычный лак',
      description: 'Классический, средний глянец',
      opacity: 0.95,
      saturation: 0.9,
      hasGloss: true,
      glossIntensity: 0.6,
    ),
  ];
}