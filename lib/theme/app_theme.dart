import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ДИЗАЙН-СИСТЕМА «Твои Ноготочки 2.0».
///
/// Палитра (утверждена):
/// - Deep Navy   #1C1C28 — тёмные панели (низ примерки, слои)
/// - Wine        #6E2233 — бренд: AppBar, главные кнопки, заголовки
/// - Blush       #F6E6EA — фоны экранов и светлые подложки
/// - Cyan        #1EC1C8 — интерактив: активные чипы, бейджи, акценты
///
/// Шрифты: Unbounded (заголовки, характер бренда) +
///          Golos Text (текст, читабельность). Оба с кириллицей.
class AppColors {
  AppColors._();

  // Тёмная семья
  static const Color navy = Color(0xFF1C1C28);
  static const Color navySurface = Color(0xFF26263A);
  static const Color navySoft = Color(0xFF33334C);

  // Бренд
  static const Color wine = Color(0xFF6E2233);
  static const Color wineDeep = Color(0xFF471523);
  static const Color wineSoft = Color(0xFF8A3A4C);

  // Светлая семья
  static const Color blush = Color(0xFFF6E6EA);
  static const Color blushDeep = Color(0xFFEFD3DB);
  static const Color card = Color(0xFFFFFFFF);

  // Акцент
  static const Color cyan = Color(0xFF1EC1C8);
  static const Color cyanDeep = Color(0xFF0E8A90);

  // Текст
  static const Color ink = Color(0xFF241B22);
  static const Color inkSoft = Color(0xFF5C5460);
  static const Color onDark = Color(0xFFF3EDF0);
  static const Color onDarkSoft = Color(0xFFB9B2C0);
}

/// Готовые градиенты для кнопок и акцентных элементов.
class AppGradients {
  AppGradients._();

  /// Главные CTA-кнопки: винный в глубину
  static const LinearGradient cta = LinearGradient(
    colors: [AppColors.wine, AppColors.wineDeep],
  );

  /// Акцентные полосы, логотип-блоки, прогресс: вино → бирюза
  static const LinearGradient accent = LinearGradient(
    colors: [AppColors.wine, AppColors.cyan],
  );

  /// Тёмные панели (низ примерки, слои): мягкая вертикаль
  static const LinearGradient darkPanel = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.navySurface, AppColors.navy],
  );
}

/// Тема приложения: единые цвета, шрифты и компонентные стили.
class AppTheme {
  AppTheme._();

  // ============ ТЕКСТ ============

  static TextTheme _textTheme() {
    return TextTheme(
      // Заголовки — Unbounded (характер бренда)
      displayLarge: GoogleFonts.unbounded(
          fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.ink),
      displayMedium: GoogleFonts.unbounded(
          fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink),
      displaySmall: GoogleFonts.unbounded(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink),
      headlineLarge: GoogleFonts.unbounded(
          fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink),
      headlineMedium: GoogleFonts.unbounded(
          fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink),
      headlineSmall: GoogleFonts.unbounded(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink),
      titleLarge: GoogleFonts.unbounded(
          fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink),
      titleMedium: GoogleFonts.golosText(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
      titleSmall: GoogleFonts.golosText(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),

      // Текст — Golos Text (читаемость)
      bodyLarge: GoogleFonts.golosText(
          fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.ink),
      bodyMedium: GoogleFonts.golosText(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.ink),
      bodySmall: GoogleFonts.golosText(
          fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.inkSoft),
      labelLarge: GoogleFonts.golosText(
          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
      labelMedium: GoogleFonts.golosText(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
      labelSmall: GoogleFonts.golosText(
          fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
    );
  }

  // ============ ТЕМА ============

  static ThemeData get light {
    final text = _textTheme();

    final ColorScheme scheme = ColorScheme.light(
      primary: AppColors.wine,
      onPrimary: Colors.white,
      primaryContainer: AppColors.wineDeep,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.cyan,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.cyanDeep,
      onSecondaryContainer: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.blushDeep,
      onSurfaceVariant: AppColors.inkSoft,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      outline: AppColors.blushDeep,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.blush,
      textTheme: text,

      // AppBar: винный, без тени, заголовок Unbounded
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.wine,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.unbounded(
            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Карточки: белые, скругление 16, мягкая тень
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: AppColors.wine.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),

      // Кнопки: винный градиент задаётся на месте через DecoratedBox,
      // здесь — базовая форма и типографика
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.wine,
          foregroundColor: Colors.white,
          elevation: 2,
          textStyle: GoogleFonts.golosText(
              fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.wine,
          side: const BorderSide(color: AppColors.wine, width: 1.5),
          textStyle: GoogleFonts.golosText(
              fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.wine,
          textStyle: GoogleFonts.golosText(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // FAB: бирюза — точка быстрого действия
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.cyan,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Чипы: активный — бирюза
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.blushDeep,
        selectedColor: AppColors.cyan,
        labelStyle: text.labelMedium!,
        secondaryLabelStyle:
            text.labelMedium!.copyWith(color: Colors.white),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // Вкладки: индикатор — бирюза
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.cyan, width: 3),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
      ),

      // Слайдеры: бирюза на светлом, на тёмных панелях
      // переопределяются локально (inactiveColor white24)
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.cyan,
        inactiveTrackColor: AppColors.blushDeep,
        thumbColor: AppColors.cyan,
        overlayColor: AppColors.cyan.withOpacity(0.15),
        trackHeight: 4,
        thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),

      // Диалоги: белые, скругление 20
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: text.headlineSmall,
      ),

      // Поля ввода: скругление 12, фокус — винный
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blushDeep),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blushDeep),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.wine, width: 2),
        ),
        labelStyle: text.bodyMedium!.copyWith(color: AppColors.inkSoft),
      ),

      // Снэкбары — тёмные
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        contentTextStyle: text.bodyMedium!.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Разделители — пудровые
      dividerTheme: const DividerThemeData(
        color: AppColors.blushDeep,
        thickness: 1,
      ),
    );
  }
}