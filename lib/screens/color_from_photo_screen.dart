import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/nail_color.dart';
import '../library/unified_library_service.dart';
import '../utils/top_message.dart';

/// Цвет из фото: мастер фоткает бутылочку лака или палитру,
/// ставит точки тапами — цвет берётся как среднее по точкам,
/// каждая точка = среднее по площадке 7×7 пикселей (без шума матрицы).
/// Перед сохранением можно довести цвет слайдерами коррекции.
class ColorFromPhotoScreen extends StatefulWidget {
  const ColorFromPhotoScreen({super.key});

  @override
  State<ColorFromPhotoScreen> createState() => _ColorFromPhotoScreenState();
}

class _PickPoint {
  final int px;
  final int py;
  final Color color;
  const _PickPoint(this.px, this.py, this.color);
}

class _ColorFromPhotoScreenState extends State<ColorFromPhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();

  File? _file;
  ui.Image? _image;
  ByteData? _pixels; // кэш rawRgba для быстрых чтений пикселей
  double _scale = 1.0;
  double _baseScale = 1.0;
  Offset _offset = Offset.zero;

  final List<_PickPoint> _points = [];
  Color _current = Colors.grey;
  bool _saving = false;

  // Коррекция «довести до как в жизни»
  double _hueShift = 0; // градусы -30..30
  double _satMul = 1.0; // 0.6..1.4
  double _lightMul = 1.0; // 0.6..1.4

  List<NailColor> _allColors = [];

  @override
  void initState() {
    super.initState();
    _pickSource(initial: true);
    UnifiedLibraryService.getAllColors().then((c) {
      if (mounted) setState(() => _allColors = c);
    });
  }

  @override
  void dispose() {
    _image?.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ============ ФОТО ============

  Future<void> _pickSource({bool initial = false}) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фото цвета', style: TextStyle(fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, size: 28),
              title: const Text('Сфотографировать',
                  style: TextStyle(fontSize: 18)),
              subtitle: const Text('бутылочку, палитру, ноготок',
                  style: TextStyle(fontSize: 13)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, size: 28),
              title:
                  const Text('Из галереи', style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      if (initial && mounted) Navigator.pop(context);
      return;
    }
    await _pickSourceWith(source);
  }

  Future<void> _pickSourceWith(ImageSource source) async {
    try {
      final XFile? photo =
          await _picker.pickImage(source: source, imageQuality: 90);
      if (photo == null) return;
      await _loadImage(File(photo.path));
    } catch (e) {
      if (mounted) {
        TopMessage.show(context, 'Ошибка фото: $e', color: Colors.red);
      }
    }
  }

  Future<void> _loadImage(File f) async {
    final bytes = await f.readAsBytes();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (i) => completer.complete(i));
    final img = await completer.future;
    final pixels = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (!mounted) return;
    setState(() {
      _file = f;
      _image?.dispose();
      _image = img;
      _pixels = pixels;
      _points.clear();
      _scale = 1.0;
      _offset = Offset.zero;
      // коррекция сбрасывается под новое фото
      _hueShift = 0;
      _satMul = 1.0;
      _lightMul = 1.0;
    });
  }

  // ============ ГЕОМЕТРИЯ И ТОЧКИ ============

  Rect _computeRect(Size zone) {
    final img = _image!;
    final s =
        math.min(zone.width / img.width, zone.height / img.height) * _scale;
    final w = img.width * s;
    final h = img.height * s;
    final cx = zone.width / 2 + _offset.dx;
    final cy = zone.height / 2 + _offset.dy;
    return Rect.fromLTWH(cx - w / 2, cy - h / 2, w, h);
  }

  /// Среднее по площадке 7×7 пикселей: убирает шум матрицы и зерно
  Color _sampleAt(int px, int py) {
    final img = _image!;
    final bytes = _pixels!;
    int r = 0, g = 0, b = 0, n = 0;
    for (int dy = -3; dy <= 3; dy++) {
      for (int dx = -3; dx <= 3; dx++) {
        final x = (px + dx).clamp(0, img.width - 1);
        final y = (py + dy).clamp(0, img.height - 1);
        final idx = (y * img.width + x) * 4;
        r += bytes.getUint8(idx);
        g += bytes.getUint8(idx + 1);
        b += bytes.getUint8(idx + 2);
        n++;
      }
    }
    return Color.fromARGB(255, r ~/ n, g ~/ n, b ~/ n);
  }

  void _onTap(Offset local, Rect rect) {
    final img = _image;
    if (img == null) return;
    if (!rect.contains(local)) {
      TopMessage.show(context, 'Тапни по фото', color: Colors.orange);
      return;
    }
    final px = ((local.dx - rect.left) / rect.width * img.width).round();
    final py = ((local.dy - rect.top) / rect.height * img.height).round();
    final color = _sampleAt(px, py);
    setState(() {
      if (_points.length >= 5) _points.removeAt(0);
      _points.add(_PickPoint(px, py, color));
    });
    _recomputeCurrent();
  }

  /// Коррекция HSL поверх среднего цвета точек
  Color _adjust(Color base) {
    final hsl = HSLColor.fromColor(base);
    double h = (hsl.hue + _hueShift) % 360;
    if (h < 0) h += 360;
    final s = (hsl.saturation * _satMul).clamp(0.0, 1.0);
    final l = (hsl.lightness * _lightMul).clamp(0.0, 1.0);
    return HSLColor.fromAHSL(1.0, h, s, l).toColor();
  }

  void _recomputeCurrent() {
    if (_points.isEmpty) return;
    int r = 0, g = 0, b = 0;
    for (final p in _points) {
      r += p.color.red;
      g += p.color.green;
      b += p.color.blue;
    }
    final n = _points.length;
    final base = Color.fromARGB(255, r ~/ n, g ~/ n, b ~/ n);
    setState(() {
      _current = _adjust(base);
    });
  }

  void _setAdj({double? hue, double? sat, double? light}) {
    setState(() {
      if (hue != null) _hueShift = hue;
      if (sat != null) _satMul = sat;
      if (light != null) _lightMul = light;
    });
    _recomputeCurrent();
  }

  // ============ ПОДСКАЗКИ ============

  String _hex(Color c) =>
      '#${c.red.toRadixString(16).padLeft(2, '0')}${c.green.toRadixString(16).padLeft(2, '0')}${c.blue.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();

  String? _nearestName() {
    if (_allColors.isEmpty || _points.isEmpty) return null;
    String? best;
    double bestD = double.infinity;
    for (final c in _allColors.where((c) => c.group != 'my')) {
      final dr = c.color.red - _current.red;
      final dg = c.color.green - _current.green;
      final db = c.color.blue - _current.blue;
      final double d = (dr * dr + dg * dg + db * db).toDouble();
      if (d < bestD) {
        bestD = d;
        best = c.name;
      }
    }
    return best;
  }

  String _autoName() {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    final now = DateTime.now();
    return 'Из фото • ${now.day} ${months[now.month - 1]}';
  }

  // ============ СОХРАНЕНИЕ ============

  Future<void> _save() async {
    if (_points.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final entered = _nameController.text.trim();
      String name = entered.isNotEmpty ? entered : _autoName();

      final taken = <String>{
        for (final c in _allColors.where((c) => c.group == 'my')) c.name,
      };
      if (taken.contains(name)) {
        int n = 2;
        while (taken.contains('$name №$n')) {
          n++;
        }
        name = '$name №$n';
      }

      final adjNote = (_hueShift.abs() > 0.5 ||
              (_satMul - 1).abs() > 0.02 ||
              (_lightMul - 1).abs() > 0.02)
          ? ' • коррекция'
          : '';
      final desc =
          'Цвет из фото${_points.length > 1 ? ' (среднее ${_points.length} точек)' : ''}$adjNote • ${_hex(_current)}';

      await UnifiedLibraryService.addCustomColor(
        name,
        _current,
        description: desc,
      );

      if (mounted) {
        Navigator.pop(
          context,
          NailColor(
            id: 'just_saved',
            name: name,
            color: _current,
            group: 'my',
            description: desc,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        TopMessage.show(context, 'Ошибка сохранения: $e', color: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    final nearest = _nearestName();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Цвет из фото', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, size: 26),
            tooltip: 'Отменить точку',
            onPressed: _points.isEmpty
                ? null
                : () {
                    setState(() => _points.removeLast());
                    _recomputeCurrent();
                  },
          ),
          IconButton(
            icon: const Icon(Icons.layers_clear, size: 26),
            tooltip: 'Очистить точки',
            onPressed:
                _points.isEmpty ? null : () => setState(() => _points.clear()),
          ),
          IconButton(
            icon: const Icon(Icons.photo_camera, size: 26),
            tooltip: 'Другое фото',
            onPressed: () => _pickSource(),
          ),
        ],
      ),
      body: Column(
        children: [
          // === ЗОНА ФОТО С ТОЧКАМИ ===
          Expanded(
            child: LayoutBuilder(
              builder: (context, cons) {
                final zone = Size(cons.maxWidth, cons.maxHeight);
                final rect =
                    _image == null ? Rect.zero : _computeRect(zone);
                return GestureDetector(
                  onScaleStart: (_) => _baseScale = _scale,
                  onScaleUpdate: (d) {
                    setState(() {
                      _scale = (_baseScale * d.scale).clamp(0.5, 5.0);
                      _offset += d.focalPointDelta;
                    });
                  },
                  onTapUp: (d) => _onTap(d.localPosition, rect),
                  child: Stack(
                    children: [
                      if (_image != null && _file != null)
                        Positioned(
                          left: rect.left,
                          top: rect.top,
                          width: rect.width,
                          height: rect.height,
                          child: Image.file(_file!, fit: BoxFit.fill),
                        ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _PointsPainter(
                            points: _points,
                            rect: rect,
                            imgW: _image?.width ?? 1,
                            imgH: _image?.height ?? 1,
                          ),
                        ),
                      ),
                      if (_image == null)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Фото ещё не выбрано',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _pickSourceWith(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Камера'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.pink,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickSourceWith(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Галерея'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.white54),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (_image != null && _points.isEmpty)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Тапни по цвету на фото\n2-3 тапа — точнее (среднее)\n2 пальца — зум\n💡 Дневной свет у окна = самый честный цвет',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // === НИЖНЯЯ ПАНЕЛЬ ===
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _points.isEmpty ? Colors.transparent : _current,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _points.isEmpty
                                ? Colors.white38
                                : Colors.white24,
                            width: 2,
                          ),
                        ),
                        child: _points.isEmpty
                            ? const Icon(Icons.colorize,
                                color: Colors.white38, size: 24)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _points.isEmpty ? '—' : _hex(_current),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              nearest != null
                                  ? 'Ближайший: $nearest'
                                  : 'Поставь точку на фото',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            Text(
                              'Точек: ${_points.length}'
                              '${_points.length > 1 ? ' • цвет = среднее' : ''}',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // === КОРРЕКЦИЯ «довести до как в жизни» ===
                  if (_points.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _miniSlider('Оттенок', _hueShift, -30, 30,
                        (v) => _setAdj(hue: v)),
                    _miniSlider('Насыщ.', _satMul, 0.6, 1.4,
                        (v) => _setAdj(sat: v)),
                    _miniSlider('Светлее', _lightMul, 0.6, 1.4,
                        (v) => _setAdj(light: v)),
                  ],

                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Название (необязательно)',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: _autoName(),
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38)),
                      focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.pink)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_points.isEmpty || _saving) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Сохранить в Мои цвета'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Компактный слайдер коррекции
  Widget _miniSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: Colors.pink,
              inactiveColor: Colors.white24,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Маркеры точек поверх фото
class _PointsPainter extends CustomPainter {
  final List<_PickPoint> points;
  final Rect rect;
  final int imgW;
  final int imgH;

  _PointsPainter({
    required this.points,
    required this.rect,
    required this.imgW,
    required this.imgH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final pos = rect.topLeft +
          Offset(p.px / imgW * rect.width, p.py / imgH * rect.height);

      canvas.drawCircle(
          pos, 11, Paint()..color = Colors.white.withOpacity(0.9));
      canvas.drawCircle(pos, 8, Paint()..color = p.color);
      canvas.drawCircle(
          pos,
          11,
          Paint()
            ..color = Colors.black54
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _PointsPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.rect != rect;
}