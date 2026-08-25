import 'package:flutter/material.dart';
import '../models/nail_pattern.dart';
import '../models/nail_shape.dart';
import '../widgets/nail_pattern_layer.dart';

/// Экран выбора рисунка (узора) и его цвета
class PatternPickerScreen extends StatefulWidget {
  final NailPattern currentPattern;
  final Color previewColor;

  const PatternPickerScreen({
    super.key,
    required this.currentPattern,
    required this.previewColor,
  });

  @override
  State<PatternPickerScreen> createState() => _PatternPickerScreenState();
}

class _PatternPickerScreenState extends State<PatternPickerScreen> {
  late NailPatternType _type;
  late Color _color;

  static const List<Color> _patternColors = [
    Colors.white,
    Colors.black,
    Color(0xFFFFD700), // Золото
    Color(0xFFC0C0C0), // Серебро
    Color(0xFFF48FB1), // Розовый
    Color(0xFFE53935), // Красный
    Color(0xFF81D4FA), // Голубой
    Color(0xFFB39DDB), // Фиолетовый
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.currentPattern.type;
    _color = widget.currentPattern.color;
  }

  void _apply() {
    Navigator.pop(context, NailPattern(type: _type, color: _color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рисунок', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Большое превью
          Center(
            child: SizedBox(
              width: 140,
              height: 180,
              child: ClipRRect(
                borderRadius: NailShapeHelper.getBorderRadius(NailShape.oval, 140, 180),
                child: Stack(
                  children: [
                    Positioned.fill(child: Container(color: widget.previewColor)),
                    Positioned.fill(
                      child: NailPatternLayer(
                        pattern: NailPattern(type: _type, color: _color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Узор',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Сетка узоров с живым превью
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: NailPatternType.values.length,
            itemBuilder: (context, index) {
              final type = NailPatternType.values[index];
              final isSelected = _type == type;

              return GestureDetector(
                onTap: () => setState(() => _type = type),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.pink : Colors.grey[300]!,
                      width: isSelected ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Positioned.fill(child: Container(color: widget.previewColor)),
                        Positioned.fill(
                          child: NailPatternLayer(
                            pattern: NailPattern(type: type, color: _color),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.white.withOpacity(0.85),
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              NailPattern.getTypeName(type),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          const Text(
            'Цвет узора',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _patternColors.map((c) {
              final isSelected = _color.value == c.value;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.pink : Colors.grey[400]!,
                      width: isSelected ? 4 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Применить', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}