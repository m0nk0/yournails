import 'package:flutter/material.dart';

/// Сообщение-ошибка СВЕРХУ экрана — не закрывает нижние кнопки
class TopMessage {
  static void show(BuildContext context, String text,
      {Color color = Colors.red,
      Duration duration = const Duration(seconds: 2)}) {
    final mq = MediaQuery.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text, textAlign: TextAlign.center),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: EdgeInsets.only(
          top: mq.padding.top + 8,
          left: 24,
          right: 24,
          bottom: mq.size.height - 120,
        ),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }
}