import 'package:flutter/material.dart';
import '../models/nail_color.dart';
import '../models/nail_material.dart';

/// Сервис базовых наборов дизайнов.
class DesignSetsService {
  /// 25 базовых цветов
  static List<NailColor> getColors() {
    return [
      // Нюд
      NailColor(id: 'nude_beige', name: 'Бежевый', color: const Color(0xFFE8D5C4), group: 'nude'),
      NailColor(id: 'nude_pink', name: 'Розовый беж', color: const Color(0xFFE8C4C4), group: 'nude'),
      NailColor(id: 'nude_milk', name: 'Молочный', color: const Color(0xFFF5F0E8), group: 'nude'),
      
      // Красный
      NailColor(id: 'red_classic', name: 'Классический', color: const Color(0xFFE53935), group: 'red'),
      NailColor(id: 'red_burgundy', name: 'Бордовый', color: const Color(0xFF8E2323), group: 'red'),
      NailColor(id: 'red_cherry', name: 'Вишнёвый', color: const Color(0xFFB24A4A), group: 'red'),
      
      // Розовый
      NailColor(id: 'pink_gentle', name: 'Нежный', color: const Color(0xFFF8BBD0), group: 'pink'),
      NailColor(id: 'pink_fuchsia', name: 'Фуксия', color: const Color(0xFFE91E63), group: 'pink'),
      NailColor(id: 'pink_dusty', name: 'Пыльная роза', color: const Color(0xFFD4A5A5), group: 'pink'),
      
      // Белый
      NailColor(id: 'white_pure', name: 'Чистый белый', color: const Color(0xFFFFFFFF), group: 'white'),
      NailColor(id: 'white_milk', name: 'Молочный', color: const Color(0xFFF8F4E6), group: 'white'),
      
      // Чёрный
      NailColor(id: 'black_gloss', name: 'Чёрный глянец', color: const Color(0xFF212121), group: 'black'),
      NailColor(id: 'black_graphite', name: 'Графит', color: const Color(0xFF424242), group: 'black'),
      
      // Синий
      NailColor(id: 'blue_light', name: 'Голубой', color: const Color(0xFF81D4FA), group: 'blue'),
      NailColor(id: 'blue_navy', name: 'Navy', color: const Color(0xFF1A237E), group: 'blue'),
      NailColor(id: 'blue_turquoise', name: 'Бирюзовый', color: const Color(0xFF26C6DA), group: 'blue'),
      
      // Зелёный
      NailColor(id: 'green_mint', name: 'Мятный', color: const Color(0xFF80CBC4), group: 'green'),
      NailColor(id: 'green_emerald', name: 'Изумрудный', color: const Color(0xFF2E7D32), group: 'green'),
      NailColor(id: 'green_khaki', name: 'Хаки', color: const Color(0xFF8B9A46), group: 'green'),
      
      // Фиолетовый
      NailColor(id: 'purple_lavender', name: 'Лавандовый', color: const Color(0xFFB39DDB), group: 'purple'),
      NailColor(id: 'purple_plum', name: 'Сливовый', color: const Color(0xFF6A1B9A), group: 'purple'),
      
      // Жёлтый
      NailColor(id: 'yellow_lemon', name: 'Лимонный', color: const Color(0xFFFFF176), group: 'yellow'),
      NailColor(id: 'yellow_gold', name: 'Золотой', color: const Color(0xFFFFD700), group: 'yellow'),
      
      // Серый
      NailColor(id: 'gray_light', name: 'Светло-серый', color: const Color(0xFFBDBDBD), group: 'gray'),
      NailColor(id: 'gray_asphalt', name: 'Мокрый асфальт', color: const Color(0xFF616161), group: 'gray'),
    ];
  }

  /// 5 материалов с эффектами
  static List<NailMaterial> getMaterials() {
    return [
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
        description: 'Матовый, прочный, приглушённый цвет',
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
}