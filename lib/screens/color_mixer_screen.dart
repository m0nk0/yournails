import 'package:flutter/material.dart';

import '../models/nail_color.dart';
import '../library/unified_library_service.dart';
import 'color_picker_screen.dart';

/// Миксер "Смешивание лаков": A + B + белила + затемнение
class ColorMixerScreen extends StatefulWidget {
  const ColorMixerScreen({super.key});

  @override
  State<ColorMixerScreen> createState() => _ColorMixerScreenState();
}

class _ColorMixerScreenState extends State<ColorMixerScreen> {
  NailColor? _colorA;
  NailColor? _colorB;
  bool _loading = true;

  double _ratio = 0.5; // 0 = весь A, 1 = весь B
  double _white = 0.0;
  double _black = 0.0;

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDefaults();
  }

  /// Резолв дефолтных цветов из Единой Библиотеки
  Future<void> _initDefaults() async {
    await UnifiedLibraryService.getFullLibrary();
    final a = UnifiedLibraryService.resolveColor('builtin_red_classic') ??
        UnifiedLibraryService.resolveColor('red_classic');
    final b = UnifiedLibraryService.resolveColor('builtin_nude_ivory') ??
        UnifiedLibraryService.resolveColor('white_pure');
    if (!mounted) return;
    setState(() {
      _colorA = a;
      _colorB = b;
      _loading = false;
    });
  }

  Color get _mixed {
    if (_colorA == null || _colorB == null) return Colors.grey;
    Color m = Color.lerp(_colorA!.color, _colorB!.color, _ratio)!;
    if (_white > 0) m = Color.lerp(m, Colors.white, _white)!;
    if (_black > 0) m = Color.lerp(m, Colors.black, _black)!;
    return m;
  }

  /// Полный рецепт — идёт в description и во временное имя применения
  String _recipeName() {
    if (_colorA == null || _colorB == null) return 'Мой цвет';
    final base = '${_colorA!.name} + ${_colorB!.name}';
    final mods = <String>[];
    if (_white > 0.01) mods.add('белила ${(_white * 100).round()}%');
    if (_black > 0.01) mods.add('темнее ${(_black * 100).round()}%');
    if ((_ratio - 0.5).abs() > 0.01) {
      mods.add('смесь ${((1 - _ratio) * 100).round()}/${(_ratio * 100).round()}');
    }
    return mods.isEmpty ? base : '$base · ${mods.join(', ')}';
  }

  /// Короткое имя для сохранения: «Микс №N» со сквозной нумерацией
  Future<String> _nextMixName() async {
    final all = await UnifiedLibraryService.getAllColors();
    final re = RegExp(r'^Микс №(\d+)$');
    int max = 0;
    for (final c in all.where((c) => c.group == 'my')) {
      final m = re.firstMatch(c.name);
      if (m != null) {
        final n = int.parse(m.group(1)!);
        if (n > max) max = n;
      }
    }
    return 'Микс №${max + 1}';
  }

  /// Уникальное имя для введённого вручную: при совпадении — №2, №3…
  Future<String> _uniqueName(String base) async {
    final all = await UnifiedLibraryService.getAllColors();
    final taken = <String>{
      for (final c in all.where((c) => c.group == 'my')) c.name,
    };
    if (!taken.contains(base)) return base;
    int n = 2;
    while (taken.contains('$base №$n')) {
      n++;
    }
    return '$base №$n';
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
    if (_colorA == null || _colorB == null) return;
    final entered = _nameController.text.trim();
    final name = entered.isNotEmpty
        ? await _uniqueName(entered)
        : await _nextMixName();
    await UnifiedLibraryService.addCustomColor(
      name,
      _mixed,
      description: _recipeName(),
    );
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
    if (_colorA == null || _colorB == null) return;
    final entered = _nameController.text.trim();
    // Временное имя: своё или полный рецепт (в саммари читается хорошо)
    final name = entered.isNotEmpty ? entered : _recipeName();
    Navigator.pop(
      context,
      NailColor(
        id: 'mixed_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        color: _mixed,
        group: 'my',
        description: _recipeName(),
      ),
    );
  }

  Widget _buildDrop(NailColor? color, bool isA) {
    final baseColor = color?.color ?? Colors.grey[300]!;
    final label = color?.name ?? '—';
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickColor(isA),
        child: Column(
          children: [
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
                shape: BoxShape.rectangle,
              ),
              child: Center(
                child: Icon(Icons.edit,
                    color: Colors.white.withValues(alpha: 0.7), size: 22),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${isA ? 'A' : 'B'}: $label',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                        color: _mixed.withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.check_circle,
                        color: Colors.white.withValues(alpha: 0.7), size: 40),
                  ),
                ),
                const SizedBox(height: 16),

                // Название: пусто = «Микс №N» при сохранении
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Название (необязательно)',
                    hintText: 'Микс №… · рецепт: ${_recipeName()}',
                  ),
                ),
                const SizedBox(height: 16),

                // Ползунок A <-> B
                Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        _colorA?.name ?? '',
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
                        _colorB?.name ?? '',
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
                      child:
                          Text('Затемнить', style: TextStyle(fontSize: 12)),
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
                        onPressed:
                            (_colorA != null && _colorB != null)
                                ? _saveToMyColors
                                : null,
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
                        onPressed:
                            (_colorA != null && _colorB != null)
                                ? _apply
                                : null,
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