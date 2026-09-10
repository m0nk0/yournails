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
/// ставит точки тапами — цвет берётся как среднее по точкам.
/// 1 тап = точный цвет, 2-3 тапа = среднее (точнее на бликующих поверхностях).
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

  /// Диалог выбора источника (показывается сразу при входе)
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
      // Отмена на входе = выход с экрана
      if (initial && mounted) Navigator.pop(context);
      return;
    }
    await _pickSourceWith(source);
  }

  /// Съёмка/выбор фото конкретным источником
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

  Color _pixelAt(int px, int py) {
    final img = _image!;
    final bytes = _pixels!;
    final x = px.clamp(0, img.width - 1);
    final y = py.clamp(0, img.height - 1);
    final idx = (y * img.width + x) * 4;
    return Color.fromARGB(
        255,
        bytes.getUint8(idx),
        bytes.getUint8(idx + 1),
        bytes.getUint8(idx + 2));
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
    final color = _pixelAt(px, py);
    setState(() {
      if (_points.length >= 5) _points.removeAt(0);
      _points.add(_PickPoint(px, py, color));
    });
    _recomputeCurrent();
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
    setState(() {
      _current = Color.fromARGB(255, r ~/ n, g ~/ n, b ~/ n);
    });
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

      final desc =
          'Цвет из фото${_points.length > 1 ? ' (среднее ${_points.length} точек)' : ''} • ${_hex(_current)}';

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
      // Ошибка сохранения теперь ВИДНА, а не молчит
      if (mounted) {
        TopMessage.show(context, 'Ошибка сохранения: $e', color: Colors.red);
      }
    } finally {
      // Кнопка всегда разблокируется, даже после ошибки
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
                      // Пустое состояние: понятные кнопки источников
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
                              'Тапни по цвету на фото\n2-3 тапа — точнее (среднее)\n2 пальца — зум',
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
                      // Пустой слот цвета: контур + пипетка вместо серого квадрата
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
                  const SizedBox(height: 10),
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

      // Внешнее кольцо — белое, для видимости на любом фоне
      canvas.drawCircle(
          pos, 11, Paint()..color = Colors.white.withOpacity(0.9));
      // Внутренний круг — сам взятый цвет
      canvas.drawCircle(pos, 8, Paint()..color = p.color);
      // Обводка
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