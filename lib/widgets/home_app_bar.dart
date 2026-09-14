import 'package:flutter/material.dart';

import 'quick_menu.dart';

/// Общая шапка с бургер-меню быстрых переходов
/// (Клиенты / Мои дизайны / На главный).
/// Кнопка «домой» убрана из всех экранов — она живёт внутри меню.
/// Можно дополнительно передать свои actions — они добавятся перед меню.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final Color? backgroundColor;
  final List<Widget>? actions; // дополнительные действия

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
        // В конце всегда бургер-меню: Клиенты / Мои дизайны / На главный
        const QuickMenuButton(),
      ],
    );
  }
}