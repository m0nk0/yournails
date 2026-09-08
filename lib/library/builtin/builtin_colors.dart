import 'package:flutter/material.dart';

import '../../models/nail_color.dart';

/// Встроенная коллекция из 60 цветов по 8 группам.
/// Соответствует паспорту проекта: Красные, Розовые, Нюд, Фиолетовые, 
/// Синие, Зелёные, Жёлтые, Тёмные.
final List<NailColor> builtinColors = [
  // ============ КРАСНЫЕ (8) ============
  NailColor(
    id: 'builtin_red_classic',
    name: 'Классический красный',
    color: Color(0xFFE53935),
    group: 'Красные',
  ),
  NailColor(
    id: 'builtin_red_burgundy',
    name: 'Бордовый',
    color: Color(0xFF8E0E00),
    group: 'Красные',
  ),
  NailColor(
    id: 'builtin_red_coral',
    name: 'Коралловый',
    color: Color(0xFFFF6F61),
    group: 'Красные',
  ),
  NailColor(
    id: 'builtin_red_scarlet',
    name: 'Алый',
    color: Color(0xFFFF2400),
    group: 'Красные',
  ),
  NailColor(
    id: 'builtin_red_cherry',
    name: 'Вишнёвый',
    color: Color(0xFFDE3163),
    group: 'Красные',
  ),
  NailColor(
    id: 'builtin_red_terracotta',
    name: 'Терракотовый',
    color: Color(0xFFE2725B),
    group: 'Красные',
  ),
  NailColor(
    id: 'builtin_red_ruby',
    name: 'Рубиновый',
    color: Color(0xFFE0115F),
    group: 'Красные',
  ),
  NailColor(
    id: 'builtin_red_garnet',
    name: 'Гранатовый',
    color: Color(0xFF733635),
    group: 'Красные',
  ),

  // ============ РОЗОВЫЕ (8) ============
  NailColor(
    id: 'builtin_pink_dusty',
    name: 'Пыльно-розовый',
    color: Color(0xFFDCAE96),
    group: 'Розовые',
  ),
  NailColor(
    id: 'builtin_pink_fuchsia',
    name: 'Фуксия',
    color: Color(0xFFFF00FF),
    group: 'Розовые',
  ),
  NailColor(
    id: 'builtin_pink_salmon',
    name: 'Лососевый',
    color: Color(0xFFFA8072),
    group: 'Розовые',
  ),
  NailColor(
    id: 'builtin_pink_peach',
    name: 'Персиковый',
    color: Color(0xFFFFCBA4),
    group: 'Розовые',
  ),
  NailColor(
    id: 'builtin_pink_bubblegum',
    name: 'Бабл-гам',
    color: Color(0xFFFFC1CC),
    group: 'Розовые',
  ),
  NailColor(
    id: 'builtin_pink_quartz',
    name: 'Розовый кварц',
    color: Color(0xFFF7CAC9),
    group: 'Розовые',
  ),
  NailColor(
    id: 'builtin_pink_powder',
    name: 'Пудровый',
    color: Color(0xFFF8BBD0),
    group: 'Розовые',
  ),
  NailColor(
    id: 'builtin_pink_magenta',
    name: 'Маджента',
    color: Color(0xFFFF0090),
    group: 'Розовые',
  ),

  // ============ НЮД (8) ============
  NailColor(
    id: 'builtin_nude_beige',
    name: 'Бежевый',
    color: Color(0xFFF5F5DC),
    group: 'Нюд',
  ),
  NailColor(
    id: 'builtin_nude_skin',
    name: 'Телесный',
    color: Color(0xFFE8BEAC),
    group: 'Нюд',
  ),
  NailColor(
    id: 'builtin_nude_caramel',
    name: 'Карамельный',
    color: Color(0xFFAF6E4D),
    group: 'Нюд',
  ),
  NailColor(
    id: 'builtin_nude_milk',
    name: 'Молочный',
    color: Color(0xFFFEFAE0),
    group: 'Нюд',
  ),
  NailColor(
    id: 'builtin_nude_sand',
    name: 'Песочный',
    color: Color(0xFFE6D7B8),
    group: 'Нюд',
  ),
  NailColor(
    id: 'builtin_nude_ivory',
    name: 'Слоновая кость',
    color: Color(0xFFFFFFF0),
    group: 'Нюд',
  ),
  NailColor(
    id: 'builtin_nude_taupe',
    name: 'Тауп',
    color: Color(0xFF9C8C7A),
    group: 'Нюд',
  ),
  NailColor(
    id: 'builtin_nude_coffee',
    name: 'Кофе с молоком',
    color: Color(0xFFC4A777),
    group: 'Нюд',
  ),

  // ============ ФИОЛЕТОВЫЕ (8) ============
  NailColor(
    id: 'builtin_purple_lavender',
    name: 'Лавандовый',
    color: Color(0xFFB39DDB),
    group: 'Фиолетовые',
  ),
  NailColor(
    id: 'builtin_purple_purple',
    name: 'Пурпурный',
    color: Color(0xFF800080),
    group: 'Фиолетовые',
  ),
  NailColor(
    id: 'builtin_purple_lilac',
    name: 'Лиловый',
    color: Color(0xFFC8A2C8),
    group: 'Фиолетовые',
  ),
  NailColor(
    id: 'builtin_purple_plum',
    name: 'Сливовый',
    color: Color(0xFF8E4585),
    group: 'Фиолетовые',
  ),
  NailColor(
    id: 'builtin_purple_amethyst',
    name: 'Аметист',
    color: Color(0xFF9966CC),
    group: 'Фиолетовые',
  ),
  NailColor(
    id: 'builtin_purple_eggplant',
    name: 'Баклажан',
    color: Color(0xFF614051),
    group: 'Фиолетовые',
  ),
  NailColor(
    id: 'builtin_purple_lilac_light',
    name: 'Сиреневый',
    color: Color(0xFFDDA0DD),
    group: 'Фиолетовые',
  ),
  NailColor(
    id: 'builtin_purple_indigo',
    name: 'Индиго',
    color: Color(0xFF4B0082),
    group: 'Фиолетовые',
  ),

  // ============ СИНИЕ (8) ============
  NailColor(
    id: 'builtin_blue_navy',
    name: 'Тёмно-синий',
    color: Color(0xFF000080),
    group: 'Синие',
  ),
  NailColor(
    id: 'builtin_blue_cobalt',
    name: 'Кобальт',
    color: Color(0xFF0047AB),
    group: 'Синие',
  ),
  NailColor(
    id: 'builtin_blue_sky',
    name: 'Небесно-голубой',
    color: Color(0xFF87CEEB),
    group: 'Синие',
  ),
  NailColor(
    id: 'builtin_blue_turquoise',
    name: 'Бирюзовый',
    color: Color(0xFF40E0D0),
    group: 'Синие',
  ),
  NailColor(
    id: 'builtin_blue_teal',
    name: 'Тиловый',
    color: Color(0xFF008080),
    group: 'Синие',
  ),
  NailColor(
    id: 'builtin_blue_sapphire',
    name: 'Сапфировый',
    color: Color(0xFF0F52BA),
    group: 'Синие',
  ),
  NailColor(
    id: 'builtin_blue_steel',
    name: 'Стальной',
    color: Color(0xFF4682B4),
    group: 'Синие',
  ),
  NailColor(
    id: 'builtin_blue_aqua',
    name: 'Аквамарин',
    color: Color(0xFF7FFFD4),
    group: 'Синие',
  ),

  // ============ ЗЕЛЁНЫЕ (7) ============
  NailColor(
    id: 'builtin_green_mint',
    name: 'Мятный',
    color: Color(0xFF80CBC4),
    group: 'Зелёные',
  ),
  NailColor(
    id: 'builtin_green_emerald',
    name: 'Изумрудный',
    color: Color(0xFF50C878),
    group: 'Зелёные',
  ),
  NailColor(
    id: 'builtin_green_olive',
    name: 'Оливковый',
    color: Color(0xFF808000),
    group: 'Зелёные',
  ),
  NailColor(
    id: 'builtin_green_khaki',
    name: 'Хаки',
    color: Color(0xFFBDB76B),
    group: 'Зелёные',
  ),
  NailColor(
    id: 'builtin_green_forest',
    name: 'Лесной',
    color: Color(0xFF228B22),
    group: 'Зелёные',
  ),
  NailColor(
    id: 'builtin_green_sage',
    name: 'Шалфей',
    color: Color(0xFFBCB88A),
    group: 'Зелёные',
  ),
  NailColor(
    id: 'builtin_green_jade',
    name: 'Нефритовый',
    color: Color(0xFF00A86B),
    group: 'Зелёные',
  ),

  // ============ ЖЁЛТЫЕ (7) ============
  NailColor(
    id: 'builtin_yellow_lemon',
    name: 'Лимонный',
    color: Color(0xFFFFF700),
    group: 'Жёлтые',
  ),
  NailColor(
    id: 'builtin_yellow_mustard',
    name: 'Горчичный',
    color: Color(0xFFFFDB58),
    group: 'Жёлтые',
  ),
  NailColor(
    id: 'builtin_yellow_gold',
    name: 'Золотой',
    color: Color(0xFFFFD700),
    group: 'Жёлтые',
  ),
  NailColor(
    id: 'builtin_yellow_amber',
    name: 'Янтарный',
    color: Color(0xFFFFBF00),
    group: 'Жёлтые',
  ),
  NailColor(
    id: 'builtin_yellow_sand',
    name: 'Песочный',
    color: Color(0xFFF4A460),
    group: 'Жёлтые',
  ),
  NailColor(
    id: 'builtin_yellow_corn',
    name: 'Кукурузный',
    color: Color(0xFFFBEC5D),
    group: 'Жёлтые',
  ),
  NailColor(
    id: 'builtin_yellow_canary',
    name: 'Канареечный',
    color: Color(0xFFFFEF00),
    group: 'Жёлтые',
  ),

  // ============ ТЁМНЫЕ (6) ============
  NailColor(
    id: 'builtin_dark_black',
    name: 'Чёрный',
    color: Color(0xFF000000),
    group: 'Тёмные',
  ),
  NailColor(
    id: 'builtin_dark_gray',
    name: 'Тёмно-серый',
    color: Color(0xFF424242),
    group: 'Тёмные',
  ),
  NailColor(
    id: 'builtin_dark_charcoal',
    name: 'Угольный',
    color: Color(0xFF36454F),
    group: 'Тёмные',
  ),
  NailColor(
    id: 'builtin_dark_navy',
    name: 'Тёмно-синий',
    color: Color(0xFF1A1A2E),
    group: 'Тёмные',
  ),
  NailColor(
    id: 'builtin_dark_burgundy',
    name: 'Тёмно-бордовый',
    color: Color(0xFF641E16),
    group: 'Тёмные',
  ),
  NailColor(
    id: 'builtin_dark_forest',
    name: 'Тёмно-зелёный',
    color: Color(0xFF013220),
    group: 'Тёмные',
  ),
];