import 'package:flutter/material.dart';
import '../models/nail_color.dart';
import '../services/custom_color_service.dart';
import 'color_picker_screen.dart';

/// Миксер "Смешивание лаков": A + B + белила + затемнение
class ColorMixerScreen extends StatefulWidget {
  const ColorMixerScreen({super.key});

  @override
  State<ColorMixerScreen> createState() => _ColorMixerScreenState();
}

class _ColorMixerScreenState extends State<ColorMixerScreen> {
    NailColor _colorA = NailColor(
    id: 'red_classic',
    name: 'Классический',
    color: const Color(0xFFE53935),
    group: 'red',
  );
  NailColor _colorB = NailColor(
    id: 'white_pure',
    name: 'Белый',
    color: const Color(0xFFFFFFFF),
    group: 'nude',
  );

  double _ratio = 0.5; // 0 = весь A, 1 = весь B
  double _white = 0.0;
  double _black = 0.0;

  final _nameController = TextEditingController();

  Color get _mixed {
    Color m = Color.lerp(_colorA.color, _colorB.color, _ratio)!;
    if (_white > 0) m = Color.lerp(m, Colors.white, _white)!;
    if (_black > 0) m = Color.lerp(m, Colors.black, _black)!;
    return m;
  }

  Future<void> _pickColor(bool isA) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ColorPickerScreen()),
    );
    if (res != null && res is NailColor) {
      setState(() {
        if (isA) {
          _colorA = res;
        } else {
          _colorB = res;
        }
      });
    }
  }

  Future<void> _saveToMyColors() async {
    final name = _nameController.text.trim().isEmpty
        ? 'Мой цвет'
        : _nameController.text.trim();
    await CustomColorService.add(name, _mixed);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Цвет "$name" сохранён в Мои цвета'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _apply() {
    final name = _nameController.text.trim().isEmpty
        ? '${_colorA.name} + ${_colorB.name}'
        : _nameController.text.trim();
    Navigator.pop(
      context,
      NailColor(
        id: 'mixed_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        color: _mixed,
        group: 'my',
      ),
    );
  }

  Widget _buildDrop(NailColor color, bool isA) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickColor(isA),
        child: Column(
          children: [
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: color.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
                shape: BoxShape.rectangle,
              ),
              child: const Center(
                child: Icon(Icons.edit, color: Colors.white70, size: 22),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${isA ? 'A' : 'B'}: ${color.name}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Смешивание лаков', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Капли A и B
          Row(
            children: [
              _buildDrop(_colorA, true),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.add, size: 28),
              ),
              _buildDrop(_colorB, false),
            ],
          ),
          const SizedBox(height: 20),

          // Большая капля-результат
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: _mixed,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[400]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _mixed.withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.check_circle, color: Colors.white70, size: 40),
            ),
          ),
          const SizedBox(height: 16),

          // Название
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Название (для сохранения)',
              hintText: 'Мой фирменный',
            ),
          ),
          const SizedBox(height: 16),

          // Ползунок A <-> B
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  _colorA.name,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _ratio,
                  min: 0,
                  max: 1,
                  activeColor: Colors.pink,
                  inactiveColor: Colors.grey[300],
                  onChanged: (v) => setState(() => _ratio = v),
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  _colorB.name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Белила
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, size: 20),
              const SizedBox(width: 6),
              const SizedBox(
                width: 90,
                child: Text('Белила', style: TextStyle(fontSize: 12)),
              ),
              Expanded(
                child: Slider(
                  value: _white,
                  min: 0,
                  max: 0.8,
                  activeColor: Colors.pink,
                  inactiveColor: Colors.grey[300],
                  onChanged: (v) => setState(() => _white = v),
                ),
              ),
            ],
          ),

          // Затемнение
          Row(
            children: [
              const Icon(Icons.dark_mode_outlined, size: 20),
              const SizedBox(width: 6),
              const SizedBox(
                width: 90,
                child: Text('Затемнить', style: TextStyle(fontSize: 12)),
              ),
              Expanded(
                child: Slider(
                  value: _black,
                  min: 0,
                  max: 0.8,
                  activeColor: Colors.pink,
                  inactiveColor: Colors.grey[300],
                  onChanged: (v) => setState(() => _black = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Кнопки
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveToMyColors,
                  icon: const Icon(Icons.bookmark_add),
                  label: const Text('В мои цвета'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Применить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}