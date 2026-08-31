import 'package:flutter/material.dart';
import '../models/nail_shape.dart';

/// Единый path ногтя. Форма берётся ИЗ NailShapeHelper —
/// мягкий квадрат остаётся мягким квадратом!
Path buildNailPath(double w, double h, NailShape shape) {
  final r = NailShapeHelper.getBorderRadius(shape, w, h);
  final rrect = RRect.fromRectAndCorners(
    Rect.fromLTWH(0, 0, w, h),
    topLeft: r.topLeft,
    topRight: r.topRight,
    bottomLeft: r.bottomLeft,
    bottomRight: r.bottomRight,
  );
  return Path()..addRRect(rrect);
}