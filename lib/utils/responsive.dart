import 'package:flutter/material.dart';

/// Адаптация под смартфон и планшет (брейкпоинты Material)
class Responsive {
  /// Планшет, если короткая сторона >= 600dp
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  /// Колонки в сетках
  static int gridColumns(BuildContext context, {int phone = 3, int tablet = 5}) =>
      isTablet(context) ? tablet : phone;

  /// Шрифт (на планшете чуть крупнее)
  static double fs(BuildContext context, double base) =>
      isTablet(context) ? base * 1.15 : base;

  /// Отступы
  static double pad(BuildContext context, {double phone = 12, double tablet = 20}) =>
      isTablet(context) ? tablet : phone;

  /// Компактный режим (телефон)
  static bool isCompact(BuildContext context) => !isTablet(context);
}