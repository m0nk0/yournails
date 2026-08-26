import 'package:flutter/material.dart';
import '../models/nail_color.dart';
import '../services/design_sets_service.dart';

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
  final List<ColorGroup> _groups = DesignSetsService.groups;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _groups.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<NailColor> _colorsForGroup(String groupId) {
    if (groupId == 'all') return _allColors;
    return _allColors.where((c) => c.group == groupId).toList();
  }

  void _selectColor(NailColor color) {
    Navigator.pop(context, color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор цвета', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
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

              return GestureDetector(
                onTap: () => _selectColor(color),
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
                      // Цвет — ИСПРАВЛЕНО: растягиваем на всю ширину
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
                      // Название
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