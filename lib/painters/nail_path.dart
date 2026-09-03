import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/nail_shape.dart';

/// Глубина дуги кутикулы (доля высоты) — пологая, как на схеме форм
const double _ry = 0.15;

/// Единый path ногтя.
/// - Базовые формы — через RRect (как было)
/// - Продвинутые — верх/бока как в первой версии + точная дуга кутикулы
///
/// ВАЖНО: дуга кутикулы добавляется через arcTo(forceMoveTo: false) —
/// она ПРОДОЛЖАЕТ тот же подпуть, контур единый, без хорды-разделителя.
Path buildNailPath(double w, double h, NailShape shape) {
  switch (shape) {
    // === БАЗОВЫЕ ФОРМЫ (через RRect, как было) ===
    case NailShape.oval:
    case NailShape.round:
    case NailShape.square:
    case NailShape.softSquare:
    case NailShape.squareOval:
      final r = NailShapeHelper.getBorderRadius(shape, w, h);
      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, w, h),
        topLeft: r.topLeft,
        topRight: r.topRight,
        bottomLeft: r.bottomLeft,
        bottomRight: r.bottomRight,
      );
      return Path()..addRRect(rrect);

    // === ПРОДВИНУТЫЕ ФОРМЫ (через Безье) ===
    case NailShape.almond:
      return _almondPath(w, h);
    case NailShape.russianAlmond:
      return _russianAlmondPath(w, h);
    case NailShape.stiletto:
      return _stilettoPath(w, h);
    case NailShape.ballerina:
      return _ballerinaPath(w, h);
    case NailShape.coffin:
      return _coffinPath(w, h);
    case NailShape.edge:
      return _edgePath(w, h);
    case NailShape.lipstick:
      return _lipstickPath(w, h);
    case NailShape.mountainPeak:
      return _mountainPeakPath(w, h);
    case NailShape.arrowHead:
      return _arrowHeadPath(w, h);
  }
}

/// Овал для дуги кутикулы: от x0 до x1, низ ровно y = h
Rect _arc(double x0, double x1, double h) =>
    Rect.fromLTRB(x0, h - 2 * _ry * h, x1, h);

// === МИНДАЛЬ: мягкое сужение к кончику ===
Path _almondPath(double w, double h) {
  final b = h * (1 - _ry);
  return Path()
    ..moveTo(w * 0.1, b)
    ..quadraticBezierTo(0, h * 0.5, w * 0.15, h * 0.15)
    ..quadraticBezierTo(w * 0.5, -h * 0.05, w * 0.85, h * 0.15)
    ..quadraticBezierTo(w, h * 0.5, w * 0.9, b)
    ..arcTo(_arc(w * 0.1, w * 0.9, h), 0, math.pi, false)
    ..close();
}

// === РУССКИЙ МИНДАЛЬ: глубже арка, длиннее кончик (тренд 2025-26) ===
Path _russianAlmondPath(double w, double h) {
  final b = h * (1 - _ry);
  return Path()
    ..moveTo(w * 0.12, b)
    ..quadraticBezierTo(w * 0.05, h * 0.55, w * 0.18, h * 0.18)
    ..cubicTo(w * 0.3, h * 0.02, w * 0.7, h * 0.02, w * 0.82, h * 0.18)
    ..quadraticBezierTo(w * 0.95, h * 0.55, w * 0.88, b)
    ..arcTo(_arc(w * 0.12, w * 0.88, h), 0, math.pi, false)
    ..close();
}

// === СТИЛЕТ: длинное острое сужение ===
Path _stilettoPath(double w, double h) {
  final b = h * (1 - _ry);
  return Path()
    ..moveTo(w * 0.15, b)
    ..quadraticBezierTo(w * 0.08, h * 0.6, w * 0.2, h * 0.25)
    ..lineTo(w * 0.5, 0)
    ..lineTo(w * 0.8, h * 0.25)
    ..quadraticBezierTo(w * 0.92, h * 0.6, w * 0.85, b)
    ..arcTo(_arc(w * 0.15, w * 0.85, h), 0, math.pi, false)
    ..close();
}

// === БАЛЕРИНА (ГРОБ): сужение + прямой срез ===
Path _ballerinaPath(double w, double h) {
  final b = h * (1 - _ry);
  return Path()
    ..moveTo(w * 0.1, b)
    ..lineTo(w * 0.2, h * 0.15)
    ..lineTo(w * 0.8, h * 0.15)
    ..lineTo(w * 0.9, b)
    ..arcTo(_arc(w * 0.1, w * 0.9, h), 0, math.pi, false)
    ..close();
}

// === ГРОБ (альтернатива балерине, чуть уже) ===
Path _coffinPath(double w, double h) {
  final b = h * (1 - _ry);
  return Path()
    ..moveTo(w * 0.15, b)
    ..lineTo(w * 0.25, h * 0.18)
    ..lineTo(w * 0.75, h * 0.18)
    ..lineTo(w * 0.85, b)
    ..arcTo(_arc(w * 0.15, w * 0.85, h), 0, math.pi, false)
    ..close();
}

// === ЭЙДЖ: ребро-«клинок» по центру ===
Path _edgePath(double w, double h) {
  final b = h * (1 - _ry);
  return Path()
    ..moveTo(w * 0.15, b)
    ..lineTo(w * 0.25, h * 0.3)
    ..lineTo(w * 0.5, 0)
    ..lineTo(w * 0.75, h * 0.3)
    ..lineTo(w * 0.85, b)
    ..arcTo(_arc(w * 0.15, w * 0.85, h), 0, math.pi, false)
    ..close();
}

// === СКОШЕННАЯ (LIPSTICK): диагональный срез ===
Path _lipstickPath(double w, double h) {
  final b = h * (1 - _ry);
  return Path()
    ..moveTo(w * 0.1, b)
    ..lineTo(w * 0.15, h * 0.2)
    ..lineTo(w * 0.85, h * 0.35)
    ..lineTo(w * 0.9, b)
    ..arcTo(_arc(w * 0.1, w * 0.9, h), 0, math.pi, false)
    ..close();
}

// === ПИК (MOUNTAIN PEAK): треугольный гребень ===
Path _mountainPeakPath(double w, double h) {
  final b = h * (1 - _ry);
  return Path()
    ..moveTo(w * 0.2, b)
    ..lineTo(w * 0.2, h * 0.3)
    ..lineTo(w * 0.5, 0)
    ..lineTo(w * 0.8, h * 0.3)
    ..lineTo(w * 0.8, b)
    ..arcTo(_arc(w * 0.2, w * 0.8, h), 0, math.pi, false)
    ..close();
}

// === СТРЕЛА: остриё с «крыльями» ===
Path _arrowHeadPath(double w, double h) {
  final b = h * (1 - _ry);
  return Path()
    ..moveTo(w * 0.15, b)
    ..lineTo(w * 0.25, h * 0.4)
    ..lineTo(w * 0.5, 0)
    ..lineTo(w * 0.75, h * 0.4)
    ..lineTo(w * 0.85, b)
    ..arcTo(_arc(w * 0.15, w * 0.85, h), 0, math.pi, false)
    ..close();
}

/// Рисуем силуэт формы ногтя (для превью в меню выбора)
void drawNailShapeSilhouette(
  Canvas canvas,
  Size size,
  NailShape shape, {
  Color color = Colors.white,
  double strokeWidth = 2,
}) {
  final path = buildNailPath(size.width, size.height, shape);
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth;
  canvas.drawPath(path, paint);
}