import 'package:flutter/material.dart';

import '../models/nail_color.dart';
import '../library/unified_library_service.dart';
import '../services/trend_palettes_service.dart';
import '../utils/top_message.dart';
import 'color_mixer_screen.dart';
import 'color_from_photo_screen.dart';

/// Экран выбора цвета.
/// Классика: вкладки групп из Единой Библиотеки (динамически) + «Мои цвета».
/// Тренды: кураторские палитры (до Этапа 3 остаются из TrendPalettesService).
class ColorPickerScreen extends StatefulWidget {
  final NailColor? selectedColor;

  const ColorPickerScreen({super.key, this.selectedColor});

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<NailColor> _allColors = [];

  /// ID вкладок в порядке: all → группы по канону → my
  List<String> _tabs = [];
  int _tabIndex = 0;
  bool _loading = true;

  // Режим: false = классика (вкладки), true = тренды (палитры)
  bool _isTrendsMode = false;

  static const List<String> _canonicalOrder = [
    'Красные',
    'Розовые',
    'Нюд',
    'Фиолетовые',
    'Синие',
    'Зелёные',
    'Жёлтые',
    'Тёмные',
  ];

  static const Map<String, String> _groupIcons = {
    'Красные': '🔴',
    'Розовые': '🌸',
    'Нюд': '🤍',
    'Фиолетовые': '🟣',
    'Синие': '🔵',
    'Зелёные': '🟢',
    'Жёлтые': '🟡',
    'Тёмные': '⚫',
    'my': '💾',
  };

  String _groupName(String id) {
    if (id == 'all') return 'Все';
    if (id == 'my') return 'Мои цвета';
    return id;
  }

  String _groupIcon(String id) => _groupIcons[id] ?? '🎨';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final colors = await UnifiedLibraryService.getAllColors();

    final available = colors.map((c) => c.group).toSet();
    final ordered = <String>[
      for (final g in _canonicalOrder)
        if (available.contains(g)) g
    ];
    for (final g in available) {
      if (g != 'my' && !ordered.contains(g)) ordered.add(g);
    }
    // Состав вкладок стабилен (My цвета всегда присутствуют),
    // поэтому TabController создаётся один раз и никогда не пересоздаётся.
    // Именно пересоздание контроллера ломало TabBarView (overflow 99895 px).
    // «Мои цвета» ПЕРВЫЕ: это рабочая палитра мастера, до неё не надо мотать.
    final tabs = <String>['my', 'all', ...ordered];

    // Контроллер создаём ОДИН раз, до setState с _loading = false
    if (_tabController == null) {
      _tabController = TabController(length: tabs.length, vsync: this);
      _tabController!.addListener(_onTabChanged);
    }

    if (!mounted) return;
    setState(() {
      _allColors = colors;
      _tabs = tabs;
      _loading = false;
    });
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {
        _tabIndex = _tabController?.index ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<NailColor> _colorsForGroup(String groupId) {
    if (groupId == 'all') return _allColors;
    return _allColors.where((c) => c.group == groupId).toList();
  }

  /// Открыть миксер. Никаких await между получением результата и pop.
  Future<void> _openMixer() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ColorMixerScreen()),
    );
    if (res != null && res is NailColor) {
      UnifiedLibraryService.invalidateCache();
      if (mounted) Navigator.pop(context, res);
    }
  }

  /// Открыть «Цвет из фото»: сохранение происходит внутри,
  /// сюда возвращается уже готовый цвет
  Future<void> _openColorFromPhoto() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ColorFromPhotoScreen()),
    );
    if (res != null && res is NailColor) {
      await _load();
      if (mounted) {
        TopMessage.show(context, 'Цвет «${res.name}» — в Моих цветах',
            color: Colors.green);
      }
    }
  }

  Future<void> _deleteCustom(NailColor color) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить цвет?', style: TextStyle(fontSize: 20)),
        content: Text('"${color.name}" будет удалён из «Моих цветов».'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await UnifiedLibraryService.deleteCustomColor(color.id);
      await _load();
    }
  }

  /// HEX-код цвета для карточки
  String _hexOf(Color c) {
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  /// Карточка цвета: свотч, полное имя, группа, HEX, рецепт.
  /// Открывается тапом по полоске с именем в сетке.
  Future<void> _showColorCard(NailColor color) async {
    final isCustom = color.group == 'my';
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          color.name,
          style: const TextStyle(fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: color.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Группа',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                Text(_groupName(color.group),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Код',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                Text(_hexOf(color.color),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            if (color.description != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  color.description!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isCustom)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: const Text('Удалить',
                  style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'pick'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Выбрать'),
          ),
        ],
      ),
    );

    if (action == 'pick') {
      if (mounted) Navigator.pop(context, color);
    } else if (action == 'delete') {
      await _deleteCustom(color);
    }
  }

  /// Открыть палитру — показать её цвета на выбор
  Future<void> _openPalette(TrendPalette palette) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PaletteDetailScreen(
          palette: palette,
          selectedColor: widget.selectedColor,
        ),
      ),
    );
    if (res != null && res is NailColor && mounted) {
      Navigator.pop(context, res);
    }
  }

  bool get _isMyColorsTab =>
      !_loading &&
      !_isTrendsMode &&
      _tabController != null &&
      _tabs.isNotEmpty &&
      _tabs[_tabIndex] == 'my';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор цвета', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _openMixer,
            icon: const Icon(Icons.palette, size: 20),
            label: const Text(
              'Миксер',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
        bottom: (_isTrendsMode || _loading || _tabController == null)
            ? const PreferredSize(
                preferredSize: Size.fromHeight(8),
                child: SizedBox(height: 8),
              )
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                tabs: _tabs
                    .map((g) => Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_groupIcon(g),
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 4),
                              Text(_groupName(g)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
      ),
      body: Column(
        children: [
          // === ПЕРЕКЛЮЧАТЕЛЬ: Классика / Тренды ===
          Container(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isTrendsMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isTrendsMode
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎨', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            'Классика',
                            style: TextStyle(
                              color: !_isTrendsMode
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isTrendsMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isTrendsMode
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            'Тренды',
                            style: TextStyle(
                              color: _isTrendsMode
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // === КОНТЕНТ ===
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _isTrendsMode
                    ? _buildTrends()
                    : _buildClassic(),
          ),
        ],
      ),
      // «+» только на вкладке «Мои цвета» = цвет из фото
      floatingActionButton: _isMyColorsTab
          ? FloatingActionButton(
              onPressed: _openColorFromPhoto,
              backgroundColor: Colors.pink,
              tooltip: 'Цвет из фото',
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            )
          : null,
    );
  }

  /// Режим «Классика» — вкладки групп из Единой Библиотеки
  Widget _buildClassic() {
    return TabBarView(
      controller: _tabController,
      children: _tabs.map((g) {
        final colors = _colorsForGroup(g);

        if (colors.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                g == 'my'
                    ? 'Пока пусто.\nСмешай цвет (🎨 Миксер сверху)\nили добавь из фото (+ снизу).'
                    : 'Пока пусто.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          );
        }

        return _buildColorsGrid(colors);
      }).toList(),
    );
  }

  /// Режим «Тренды» — сетка палитр
  Widget _buildTrends() {
    final palettes = TrendPalettesService.getPalettes();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: palettes.length,
      itemBuilder: (context, index) {
        return _buildPaletteCard(palettes[index]);
      },
    );
  }

  /// Карточка палитры: номер, название, веер цветов
  Widget _buildPaletteCard(TrendPalette palette) {
    return GestureDetector(
      onTap: () => _openPalette(palette),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      palette.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                palette.subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: palette.colors.map((c) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: c.color,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.black12, width: 0.5),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Сетка цветов.
  /// Тап по свотчу = выбрать. Тап по полоске с именем = карточка цвета.
  /// Долгое нажатие = удалить (только свои).
  Widget _buildColorsGrid(List<NailColor> colors) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isSelected = widget.selectedColor?.id == color.id;
        final isCustom = color.group == 'my';

        return GestureDetector(
          onTap: () => Navigator.pop(context, color),
          onLongPress: isCustom ? () => _deleteCustom(color) : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.pink : Colors.grey[300]!,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: color.color,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(Icons.check_circle,
                                color: Colors.white, size: 40),
                          )
                        : null,
                  ),
                ),
                // Полоска с именем: тап = карточка с подробностями
                GestureDetector(
                  onTap: () => _showColorCard(color),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.white,
                    child: Text(
                      color.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.pink : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Экран конкретной палитры: 6 цветов на выбор
class _PaletteDetailScreen extends StatelessWidget {
  final TrendPalette palette;
  final NailColor? selectedColor;

  const _PaletteDetailScreen({
    required this.palette,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(palette.name, style: const TextStyle(fontSize: 18)),
            Text(
              palette.subtitle,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: palette.colors.length,
        itemBuilder: (context, index) {
          final color = palette.colors[index];
          final isSelected = selectedColor?.id == color.id;
          return GestureDetector(
            onTap: () => Navigator.pop(context, color),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.pink : Colors.grey[300]!,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: color.color,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(Icons.check_circle,
                                  color: Colors.white, size: 40),
                            )
                          : null,
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.white,
                    child: Text(
                      color.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.pink : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}