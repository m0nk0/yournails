import 'package:flutter/material.dart';
import '../models/selected_design.dart';
import 'color_picker_screen.dart';
import 'material_picker_screen.dart';

class DesignSelectionScreen extends StatefulWidget {
  final SelectedDesign currentDesign;

  const DesignSelectionScreen({super.key, required this.currentDesign});

  @override
  State<DesignSelectionScreen> createState() => _DesignSelectionScreenState();
}

class _DesignSelectionScreenState extends State<DesignSelectionScreen> {
  late SelectedDesign _design;

  @override
  void initState() {
    super.initState();
    _design = widget.currentDesign;
  }

  /// Открыть выбор цвета
  Future<void> _openColorPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ColorPickerScreen(
          selectedColor: _design.color,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _design = SelectedDesign(
          color: result,
          material: _design.material,
        );
      });
    }
  }

  /// Открыть выбор материала
  Future<void> _openMaterialPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialPickerScreen(
          selectedMaterial: _design.material,
          previewColor: _design.color?.color ?? Colors.pink,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _design = SelectedDesign(
          color: _design.color,
          material: result,
        );
      });
    }
  }

  /// Применить дизайн и вернуться
  void _applyDesign() {
    Navigator.pop(context, _design);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор дизайна', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Превью текущего выбора
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.pink[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ваш выбор:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Цвет: ${_design.color?.name ?? 'Не выбран'}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Материал: ${_design.material?.name ?? 'Не выбран'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),

          // Кнопки выбора
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Цвет
                _buildSelectionCard(
                  icon: Icons.palette,
                  title: 'Цвет',
                  subtitle: _design.color?.name ?? 'Выберите цвет',
                  color: _design.color?.color ?? Colors.grey[300]!,
                  onTap: _openColorPicker,
                ),
                const SizedBox(height: 12),

                // Материал
                _buildSelectionCard(
                  icon: Icons.diamond,
                  title: 'Материал',
                  subtitle: _design.material?.name ?? 'Выберите материал',
                  color: Colors.pink[100]!,
                  onTap: _openMaterialPicker,
                ),
                const SizedBox(height: 12),

                // Рисунок (заглушка)
                _buildSelectionCard(
                  icon: Icons.auto_awesome,
                  title: 'Рисунок',
                  subtitle: 'Скоро',
                  color: Colors.grey[300]!,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Рисунки будут добавлены позже'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Кнопка применить
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _design.hasColor ? _applyDesign : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Применить дизайн',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Карточка выбора
  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, size: 32),
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}