import 'dart:async';

import 'package:flutter/material.dart';

/// Центрированные всплывающие сообщения приложения.
/// Единый модуль: все экраны вызывают TopMessage.show(...).
///
/// Поведение:
///  - карточка по центру экрана (не уезжает за края)
///  - иконка статуса по цвету: зелёный = ОК, красный = ошибка,
///    оранжевый = предупреждение, остальное = инфо
///  - плавное появление/исчезание, держится 2.2 секунды
///  - не перехватывает тапы (IgnorePointer)
///  - новое сообщение мгновенно заменяет предыдущее
class TopMessage {
  TopMessage._();

  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String text, {
    Color? color,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    final overlay = Overlay.of(context);

    // Мгновенно убираем предыдущее сообщение
    _current?.remove();
    _current = null;

    final accent = color ?? const Color(0xFF9E9E9E);
    final ic = icon ?? _iconFor(color);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopMessageWidget(
        text: text,
        accent: accent,
        icon: ic,
        duration: duration,
        onDone: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  /// Иконка статуса по цвету сообщения
  static IconData _iconFor(Color? c) {
    if (c == null) return Icons.info_outline;
    final v = c.toARGB32();
    if (v == Colors.green.toARGB32() || v == Colors.green[600]!.toARGB32()) {
      return Icons.check_circle_outline;
    }
    if (v == Colors.red.toARGB32() || v == Colors.red[600]!.toARGB32()) {
      return Icons.error_outline;
    }
    if (v == Colors.orange.toARGB32() || v == Colors.orange[600]!.toARGB32()) {
      return Icons.warning_amber_rounded;
    }
    return Icons.info_outline;
  }
}

class _TopMessageWidget extends StatefulWidget {
  final String text;
  final Color accent;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDone;

  const _TopMessageWidget({
    required this.text,
    required this.accent,
    required this.icon,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_TopMessageWidget> createState() => _TopMessageWidgetState();
}

class _TopMessageWidgetState extends State<_TopMessageWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    _timer = Timer(widget.duration, () async {
      if (!mounted) return;
      await _ctrl.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.center,
        child: FadeTransition(
          opacity: _ctrl,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xE6202020),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.accent.withValues(alpha: 0.65),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: widget.accent, size: 26),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}