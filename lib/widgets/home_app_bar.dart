import 'package:flutter/material.dart';

/// Общая шапка с кнопкой "Домой" (возврат на главный экран одним тапом).
/// Можно дополнительно передать свои actions — они добавятся перед "Домой".
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final Color? backgroundColor;
  final List<Widget>? actions;  // НОВОЕ: дополнительные действия

  const HomeAppBar({
    super.key,
    required this.title,
    this.backgroundColor,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      actions: [
        // Сначала пользовательские действия (если есть)
        if (actions != null) ...actions!,
        // В конце всегда кнопка "Домой"
        IconButton(
          icon: const Icon(Icons.home, size: 28),
          tooltip: 'На главную',
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ],
    );
  }
}