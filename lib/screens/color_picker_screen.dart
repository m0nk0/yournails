import 'package:flutter/material.dart';
import '../models/nail_color.dart';
import '../services/design_sets_service.dart';

class ColorPickerScreen extends StatelessWidget {
  final NailColor? selectedColor;

  const ColorPickerScreen({super.key, this.selectedColor});

  @override
  Widget build(BuildContext context) {
    final colors = DesignSetsService.getColors();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор цвета', style: TextStyle(fontSize: 22)),
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
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
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
                children: [
                  // Цвет
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.color,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.white, size: 40)
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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