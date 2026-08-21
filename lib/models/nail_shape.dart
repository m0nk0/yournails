import 'package:flutter/material.dart';

/// Формы ногтей (как в реальном маникюре)
enum NailShape {
  oval,       // Овальная
  round,      // Круглая
  square,     // Квадратная
  softSquare, // Мягкий квадрат
  squareOval, // Квадратно-овальная
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
    }
  }

  /// BorderRadius для формы ногтя.
  ///
  /// АНАТОМИЯ НОГТЯ:
  /// - Низ (кутикула) ВСЕГДА скруглён — одинаков для всех форм
  /// - Верх (свободный край) МЕНЯЕТСЯ — это и есть форма
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
    }
  }
}