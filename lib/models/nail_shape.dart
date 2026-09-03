import 'package:flutter/material.dart';

/// Формы ногтей (как в реальном маникюре)
enum NailShape {
  // === БАЗОВЫЕ (через BorderRadius) ===
  oval,       // Овальная
  round,      // Круглая
  square,     // Квадратная
  softSquare, // Мягкий квадрат
  squareOval, // Квадратно-овальная

  // === ПРОДВИНУТЫЕ (через Безье) ===
  almond,     // Миндаль
  russianAlmond, // Русский миндаль (тренд 2025-26)
  stiletto,   // Стилет (острый длинный)
  ballerina,  // Балерина (гроб)
  coffin,     // Гроб (альтернатива балерине)
  edge,       // Эйдж (ребро по центру)
  lipstick,   // Скошенная (диагональ)
  mountainPeak, // Пик (треугольный гребень)
  arrowHead,  // Стрела (остриё с крыльями)
}

/// Помощник для получения формы
class NailShapeHelper {
  /// Название формы
  static String getName(NailShape shape) {
    switch (shape) {
      case NailShape.oval:
        return 'Овальная';
      case NailShape.round:
        return 'Круглая';
      case NailShape.square:
        return 'Квадратная';
      case NailShape.softSquare:
        return 'Мягкий квадрат';
      case NailShape.squareOval:
        return 'Квадратно-овальная';
      case NailShape.almond:
        return 'Миндаль';
      case NailShape.russianAlmond:
        return 'Русский миндаль';
      case NailShape.stiletto:
        return 'Стилет';
      case NailShape.ballerina:
        return 'Балерина';
      case NailShape.coffin:
        return 'Гроб';
      case NailShape.edge:
        return 'Эйдж';
      case NailShape.lipstick:
        return 'Скошенная';
      case NailShape.mountainPeak:
        return 'Пик';
      case NailShape.arrowHead:
        return 'Стрела';
    }
  }

  /// BorderRadius для формы ногтя.
  ///
  /// АНАТОМИЯ НОГТЯ:
  /// - Низ (кутикула) ВСЕГДА скруглён — одинаков для всех форм
  /// - Верх (свободный край) МЕНЯЕТСЯ — это и есть форма
  ///
  /// ВАЖНО: для продвинутых форм (миндаль, стилет и т.д.) возвращает
  /// BorderRadius.zero — они строятся через buildNailPath с кривыми Безье
  static BorderRadius getBorderRadius(NailShape shape, double width, double height) {
    // Общий низ для всех форм (кутикула)
    final bottomLeft = Radius.elliptical(width * 0.5, height * 0.45);
    final bottomRight = Radius.elliptical(width * 0.5, height * 0.45);

    switch (shape) {
      case NailShape.oval:
        // Овальная: высокий плавный купол
        return BorderRadius.only(
          topLeft: Radius.elliptical(width * 0.5, height * 0.45),
          topRight: Radius.elliptical(width * 0.5, height * 0.45),
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        );

      case NailShape.round:
        // Круглая: короткий полукруглый купол
        return BorderRadius.only(
          topLeft: Radius.elliptical(width * 0.5, height * 0.32),
          topRight: Radius.elliptical(width * 0.5, height * 0.32),
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        );

      case NailShape.square:
        // Квадратная: почти прямой верх, лёгкий изгиб углов
        return BorderRadius.only(
          topLeft: Radius.elliptical(width * 0.12, height * 0.06),
          topRight: Radius.elliptical(width * 0.12, height * 0.06),
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        );

      case NailShape.softSquare:
        // Мягкий квадрат: прямой верх, скруглённые углы
        return BorderRadius.only(
          topLeft: Radius.elliptical(width * 0.25, height * 0.14),
          topRight: Radius.elliptical(width * 0.25, height * 0.14),
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        );

      case NailShape.squareOval:
        // Квадратно-овальная: слегка изогнутый верх
        return BorderRadius.only(
          topLeft: Radius.elliptical(width * 0.40, height * 0.28),
          topRight: Radius.elliptical(width * 0.40, height * 0.28),
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        );

      // === ПРОДВИНУТЫЕ ФОРМЫ (через Безье в buildNailPath) ===
      case NailShape.almond:
      case NailShape.russianAlmond:
      case NailShape.stiletto:
      case NailShape.ballerina:
      case NailShape.coffin:
      case NailShape.edge:
      case NailShape.lipstick:
      case NailShape.mountainPeak:
      case NailShape.arrowHead:
        // Эти формы строятся через кривые Безье, не через BorderRadius
        return BorderRadius.only(
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        );
    }
  }
}