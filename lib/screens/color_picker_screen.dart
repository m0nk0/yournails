import 'package:flutter/material.dart';
import '../models/nail_color.dart';
import '../services/design_sets_service.dart';
import '../services/custom_color_service.dart';
import 'color_mixer_screen.dart';

class ColorPickerScreen extends StatefulWidget {
  final NailColor? selectedColor;

  const ColorPickerScreen({super.key, this.selectedColor});

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<NailColor> _allColors = DesignSetsService.getColors();
  List<NailColor> _customColors = [];

  // Группы + вкладка "Мои цвета"
  final List<ColorGroup> _groups = const [
    ColorGroup(id: 'all', name: 'Все', icon: '🎨'),
    ColorGroup(id: 'red', name: 'Красные', icon: '🔴'),
    ColorGroup(id: 'pink', name: 'Розовые', icon: '🌸'),
    ColorGroup(id: 'nude', name: 'Нюд', icon: '🤍'),
    ColorGroup(id: 'purple', name: 'Фиолет', icon: '🟣'),
    ColorGroup(id: 'blue', name: 'Синие', icon: '🔵'),
    ColorGroup(id: 'green', name: 'Зелёные', icon: '🟢'),
    ColorGroup(id: 'yellow', name: 'Жёлтые', icon: '🟡'),
    ColorGroup(id: 'dark', name: 'Тёмные', icon: '⚫'),
    ColorGroup(id: 'my', name: 'Мои цвета', icon: '💾'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _groups.length, vsync: this);
    _loadCustom();
  }

  Future<void> _loadCustom() async {
    final custom = await CustomColorService.load();
    if (mounted) {
      setState(() => _customColors = custom);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<NailColor> _colorsForGroup(String groupId) {
    if (groupId == 'all') return [..._allColors, ..._customColors];
    if (groupId == 'my') return _customColors;
    return _allColors.where((c) => c.group == groupId).toList();
  }

  Future<void> _openMixer() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ColorMixerScreen()),
    );
    if (res != null && res is NailColor) {
      // Применяем смешанный цвет сразу
      if (mounted) Navigator.pop(context, res);
    }
  }

  Future<void> _deleteCustom(NailColor color) async {
    await CustomColorService.delete(color.id);
    await _loadCustom();
  }

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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          tabs: _groups
              .map((g) => Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(g.icon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(g.name),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _groups.map((g) {
          final colors = _colorsForGroup(g.id);

          if (colors.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Пока пусто.\nСмешайте цвет (иконка 🧪 сверху) и сохраните в "Мои цвета".',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            );
          }

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
          );
        }).toList(),
      ),
    );
  }
}