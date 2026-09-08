import '../models/nail_color.dart';
import '../models/nail_material.dart';
import '../models/nail_pattern.dart';
import '../services/library_service.dart';
import '../services/design_sets_service.dart';
import '../services/trend_palettes_service.dart';
import 'builtin_library_service.dart';
import 'design_library.dart';

/// Единый сервис библиотеки.
/// Объединяет встроенные данные (60 цветов, 5 материалов, 7 паттернов)
/// с пользовательскими данными ("Мои цвета", свои материалы).
class UnifiedLibraryService {
  static DesignLibrary? _unifiedLibrary;

  /// Получить полную библиотеку: встроенные + пользовательские данные.
  /// Кэшируется. При изменении пользовательских данных вызывать [invalidateCache].
  static Future<DesignLibrary> getFullLibrary() async {
    if (_unifiedLibrary != null) {
      return _unifiedLibrary!;
    }

    // Загружаем встроенную библиотеку
    final builtin = await BuiltinLibraryService.getLibrary();

    // Загружаем пользовательские данные
    final customColors = await LibraryService.getCustomColors();
    final customMaterials = await LibraryService.getCustomMaterials();

    // Объединяем: встроенные цвета + пользовательские цвета
    final allColors = [...builtin.colors, ...customColors];

    // Объединяем: встроенные материалы + пользовательские материалы
    final allMaterials = [...builtin.materials, ...customMaterials];

    // Паттерны пока только встроенные (пользовательские паттерны — задел на будущее)
    final allPatterns = [...builtin.patterns];

    // Обновляем манифест с учётом объединения
    final unifiedManifest = builtin.manifest.copyWith(
      colorCount: allColors.length,
      materialCount: allMaterials.length,
      patternCount: allPatterns.length,
    );

    _unifiedLibrary = DesignLibrary(
      manifest: unifiedManifest,
      colors: allColors,
      materials: allMaterials,
      patterns: allPatterns,
    );

    return _unifiedLibrary!;
  }

  // ============ СИНХРОННЫЕ РЕЗОЛВЕРЫ (с поддержкой старых ID) ============

  /// Найти цвет по ID: новая библиотека → старая классика → трендовые палитры.
  /// Работает синхронно, если кэш уже прогрет (getFullLibrary вызывался ранее).
  static NailColor? resolveColor(String? id) {
    if (id == null) return null;

    // 1. Новая единая библиотека (кэш)
    final cached = _unifiedLibrary?.colors;
    if (cached != null) {
      for (final c in cached) {
        if (c.id == id) return c;
      }
    }

    // 2. Legacy: классические цвета старого сервиса
    for (final c in DesignSetsService.getColors()) {
      if (c.id == id) return c;
    }

    // 3. Legacy: трендовые палитры
    for (final p in TrendPalettesService.getPalettes()) {
      for (final c in p.colors) {
        if (c.id == id) return c;
      }
    }

    return null;
  }

  /// Найти материал по ID: новая библиотека → старые материалы.
  static NailMaterial? resolveMaterial(String? id) {
    if (id == null) return null;

    // 1. Новая единая библиотека (кэш)
    final cached = _unifiedLibrary?.materials;
    if (cached != null) {
      for (final m in cached) {
        if (m.id == id) return m;
      }
    }

    // 2. Legacy: материалы старого сервиса
    for (final m in DesignSetsService.getMaterials()) {
      if (m.id == id) return m;
    }

    return null;
  }

  // ============ АСИНХРОННЫЙ API ============

  /// Получить все цвета (встроенные + пользовательские)
  static Future<List<NailColor>> getAllColors() async {
    final library = await getFullLibrary();
    return library.colors;
  }

  /// Получить все материалы (встроенные + пользовательские)
  static Future<List<NailMaterial>> getAllMaterials() async {
    final library = await getFullLibrary();
    return library.materials;
  }

  /// Получить все паттерны
  static Future<List<NailPattern>> getAllPatterns() async {
    final library = await getFullLibrary();
    return library.patterns;
  }

  /// Получить цвета по группе
  static Future<List<NailColor>> getColorsByGroup(String group) async {
    final library = await getFullLibrary();
    return library.getColorsByGroup(group);
  }

  /// Получить все доступные группы цветов
  static Future<List<String>> getAvailableColorGroups() async {
    final library = await getFullLibrary();
    return library.getAvailableColorGroups();
  }

  /// Найти цвет по ID (ищет и во встроенных, и в пользовательских, и в legacy)
  static Future<NailColor?> findColorById(String id) async {
    await getFullLibrary();
    return resolveColor(id);
  }

  /// Найти материал по ID
  static Future<NailMaterial?> findMaterialById(String id) async {
    await getFullLibrary();
    return resolveMaterial(id);
  }

  /// Сброс кэша. Вызывать после добавления/удаления пользовательских данных.
  static void invalidateCache() {
    _unifiedLibrary = null;
  }

  /// Полная перезагрузка: сброс кэша + повторная загрузка
  static Future<DesignLibrary> reload() async {
    invalidateCache();
    return getFullLibrary();
  }
}