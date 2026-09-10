import 'package:flutter/material.dart';

import '../models/nail_material.dart';
import '../models/nail_shape.dart';
import '../library/unified_library_service.dart';
import '../painters/nail_path.dart';
import '../utils/top_message.dart';

/// Редактор своего материала: имя + пресеты + 3 слайдера + живой ноготь-превью.
/// Сохранение — через UnifiedLibraryService.addCustomMaterial.
class MaterialEditorScreen extends StatefulWidget {
  const MaterialEditorScreen({super.key});

  @override
  State<MaterialEditorScreen> createState() => _MaterialEditorScreenState();
}

class _Preset {
  final String name;
  final double opacity;
  final double saturation;
  final bool hasGloss;
  final double glossIntensity;
  const _Preset({
    required this.name,
    required this.opacity,
    required this.saturation,
    required this.hasGloss,
    required this.glossIntensity,
  });
}

class _MaterialEditorScreenState extends State<MaterialEditorScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  double _opacity = 1.0;
  double _saturation = 1.0;
  bool _hasGloss = true;
  double _glossIntensity = 0.5;

  bool _saving = false;

  static const List<_Preset> _presets = [
    _Preset(
      name: 'Гель-лак',
      opacity: 1.0,
      saturation: 1.0,
      hasGloss: true,
      glossIntensity: 0.5,
    ),
    _Preset(
      name: 'Матовый топ',
      opacity: 1.0,
      saturation: 0.85,
      hasGloss: false,
      glossIntensity: 0.0,
    ),
    _Preset(
      name: 'Хром',
      opacity: 1.0,
      saturation: 0.6,
      hasGloss: true,
      glossIntensity: 1.0,
    ),
    _Preset(
      name: 'Велюр',
      opacity: 1.0,
      saturation: 0.9,
      hasGloss: false,
      glossIntensity: 0.05,
    ),
    _Preset(
      name: 'Нюд',
      opacity: 0.55,
      saturation: 1.0,
      hasGloss: true,
      glossIntensity: 0.4,
    ),
  ];

  /// Бордовая подложка — как реальный гель-лак, хорошо видны все эффекты
  static const Color _previewColor = Color(0xFF8B1A1A);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(_Preset p) {
    setState(() {
      _opacity = p.opacity;
      _saturation = p.saturation;
      _hasGloss = p.hasGloss;
      _glossIntensity = p.glossIntensity;
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      TopMessage.show(context, 'Введите название материала',
          color: Colors.orange);
      return;
    }
    setState(() => _saving = true);

    try {
           final material = NailMaterial(
        id: 'mat_custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: _descCtrl.text.trim().isEmpty
            ? 'Свой материал мастера'
            : _descCtrl.text.trim(),
        opacity: _opacity,
        saturation: _saturation,
        hasGloss: _hasGloss,
        glossIntensity: _glossIntensity,
      );
      await UnifiedLibraryService.addCustomMaterial(material);

      if (mounted) {
        TopMessage.show(context, 'Материал «$name» сохранён',
            color: Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        TopMessage.show(context, 'Ошибка сохранения: $e', color: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Текущий материал — собирается из слайдеров для живого превью
  NailMaterial get _current => NailMaterial(
        id: 'preview',
        name: 'preview',
        description: '',
        opacity: _opacity,
        saturation: _saturation,
        hasGloss: _hasGloss,
        glossIntensity: _glossIntensity,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title:
            const Text('Новый материал', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === ЖИВОЙ НОГОТЬ-ПРЕВЬЮ ===
              Center(
                child: SizedBox(
                  width: 120,
                  height: 180,
                  child: _NailMaterialPreview(
                    baseColor: _previewColor,
                    material: _current,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Эффект на бордовом гель-лаке',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),

              const SizedBox(height: 20),

              // === ИМЯ + ОПИСАНИЕ ===
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Название *',
                  hintText: 'Матовый топ клиента',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Описание (опционально)',
                  hintText: 'Рецепт, бренд, особенности',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // === ПРЕСЕТЫ ===
              Text(
                'Старт с заготовки',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _presets.map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Icon(Icons.tune, size: 16, color: Colors.pink),
                        label: Text(p.name),
                        onPressed: () => _applyPreset(p),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // === СЛАЙДЕРЫ ===
              _sliderRow('Прозрачность', _opacity, 0.1, 1.0,
                  (v) => setState(() => _opacity = v)),
              _sliderRow('Насыщенность', _saturation, 0.0, 1.0,
                  (v) => setState(() => _saturation = v)),
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Colors.pink, size: 20),
                  const SizedBox(width: 8),
                  const SizedBox(
                      width: 110, child: Text('Глянец')),
                  Switch(
                    value: _hasGloss,
                    activeColor: Colors.pink,
                    onChanged: (v) => setState(() => _hasGloss = v),
                  ),
                ],
              ),
              if (_hasGloss)
                _sliderRow('Интенсивность', _glossIntensity, 0.0, 1.0,
                    (v) => setState(() => _glossIntensity = v)),

              const SizedBox(height: 24),

              // === СОХРАНИТЬ ===
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Сохранить материал',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliderRow(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.tune, color: Colors.pink, size: 20),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: Colors.pink,
              inactiveColor: Colors.pink.withOpacity(0.15),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ноготь-превью с эффектом материала (форма + цвет + глянец)
class _NailMaterialPreview extends StatelessWidget {
  final Color baseColor;
  final NailMaterial material;

  const _NailMaterialPreview({
    required this.baseColor,
    required this.material,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NailPreviewPainter(baseColor: baseColor, material: material),
    );
  }
}

class _NailPreviewPainter extends CustomPainter {
  final Color baseColor;
  final NailMaterial material;

  _NailPreviewPainter({required this.baseColor, required this.material});

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildNailPath(size.width, size.height, NailShape.oval);

    // Применяем насыщенность
    final hsl = HSLColor.fromColor(baseColor);
    final adjusted = hsl
        .withSaturation((hsl.saturation * material.saturation).clamp(0.0, 1.0))
        .toColor();

    // Базовый цвет с прозрачностью
    canvas.drawPath(
      path,
      Paint()..color = adjusted.withOpacity(material.opacity),
    );

    // Глянец сверху
    if (material.hasGloss && material.glossIntensity > 0) {
      canvas.save();
      canvas.clipPath(path);
      final r = size.height * 0.7;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white
                  .withOpacity(material.glossIntensity * 0.45),
              Colors.white
                  .withOpacity(material.glossIntensity * 0.15),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.7],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
      // Лёгкий блик-дуга сверху
      canvas.drawOval(
        Rect.fromCircle(
            center: Offset(size.width * 0.35, size.height * 0.15),
            radius: r * 0.25),
        Paint()
          ..color =
              Colors.white.withOpacity(material.glossIntensity * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.restore();
    }

    // Обводка
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _NailPreviewPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor ||
      oldDelegate.material.opacity != material.opacity ||
      oldDelegate.material.saturation != material.saturation ||
      oldDelegate.material.hasGloss != material.hasGloss ||
      oldDelegate.material.glossIntensity != material.glossIntensity;
}