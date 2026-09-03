import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/nail_zone.dart';
import '../models/selected_design.dart';
import '../models/nail_shape.dart';
import '../models/nail_pattern.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/nail_3d_renderer.dart';
import '../painters/realistic_nail_painter.dart';
import '../painters/socket_groove.dart';
import '../painters/nail_path.dart';
import 'result_screen.dart';
import 'design_selection_screen.dart';

class EditScreen extends StatefulWidget {
  final File imageFile;

  const EditScreen({super.key, required this.imageFile});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  Offset _frameCenter = Offset.zero;
  double _frameWidth = 100;
  double _frameHeight = 140;
  double _rotation = 0.0;
  Offset _imageOffset = Offset.zero;
  double _imageScale = 1.0;
  double _baseScale = 1.0;
  SelectedDesign? _selectedDesign;
  NailShape _shape = NailShape.oval;
  double _density = 2.0;
  double _brightness = 1.0;
  NailPattern _pattern = const NailPattern();

  // 3D-параметры
  double _edgeDarken = 0.3;
  double _highlightIntensity = 0.5;
  double _shadowIntensity = 0.4;

  // Параметры лунки (кутикулы)
  double _cuticleWidth = 1.0;
  double _cuticleDepth = 0.5;
  double _cuticleLength = 0.8;
  int _cuticleTone = 1;

  // Режим панели: 0 = базовый, 1 = 3D, 2 = кутикула, 3 = формы
  int _mode = 0;

  // Рамка
  bool _showFrame = true;

  // Слои (как в фотошопе)
  bool _showNailLayer = true;
  bool _showCuticleLayer = true;
  bool _showBgLayer = true;
  bool _lockNail = false;
  bool _lockBg = false;

  bool _initialized = false;

  bool get _hasDesign => _selectedDesign != null && _selectedDesign!.hasColor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final size = MediaQuery.of(context).size;
      _frameCenter = Offset(size.width / 2, size.height / 2.5);
      _initialized = true;
    }
  }

  void _onPhotoScaleStart(ScaleStartDetails details) {
    _baseScale = _imageScale;
  }

  void _onPhotoScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _imageOffset += details.focalPointDelta;
      _imageScale = (_baseScale * details.scale).clamp(0.5, 4.0);
    });
  }

  SelectedDesign _buildCurrentDesign() {
    return SelectedDesign(
      color: _selectedDesign?.color,
      material: _selectedDesign?.material,
      shape: _shape,
      density: _density,
      brightness: _brightness,
      pattern: _pattern,
      patternPath: _selectedDesign?.patternPath,
      patternName: _selectedDesign?.patternName,
      edgeDarken: _edgeDarken,
      highlightIntensity: _highlightIntensity,
      shadowIntensity: _shadowIntensity,
      cuticleWidth: _cuticleWidth,
      cuticleDepth: _cuticleDepth,
      cuticleLength: _cuticleLength,
      cuticleTone: _cuticleTone,
    );
  }

  Future<void> _openDesignSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DesignSelectionScreen(currentDesign: _buildCurrentDesign()),
      ),
    );

    if (result != null && result is SelectedDesign) {
      setState(() {
        _selectedDesign = result;
        _shape = result.shape;
        _density = result.density;
        _brightness = result.brightness;
        _pattern = result.pattern;
        _edgeDarken = result.edgeDarken;
        _highlightIntensity = result.highlightIntensity;
        _shadowIntensity = result.shadowIntensity;
        _cuticleWidth = result.cuticleWidth;
        _cuticleDepth = result.cuticleDepth;
        _cuticleLength = result.cuticleLength;
        _cuticleTone = result.cuticleTone;
      });
    }
  }

  void _saveAndNext() {
    if (!_hasDesign) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите дизайн'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final zone = NailZone(
      id: 'nail_1',
      x: _frameCenter.dx,
      y: _frameCenter.dy,
      width: _frameWidth,
      height: _frameHeight,
      rotation: _rotation,
      fingerIndex: 0,
    );

    final design = SelectedDesign(
      color: _selectedDesign!.color,
      material: _selectedDesign!.material,
      shape: _shape,
      density: _density,
      brightness: _brightness,
      pattern: _pattern,
      patternPath: _selectedDesign!.patternPath,
      patternName: _selectedDesign!.patternName,
      edgeDarken: _edgeDarken,
      highlightIntensity: _highlightIntensity,
      shadowIntensity: _shadowIntensity,
      cuticleWidth: _cuticleWidth,
      cuticleDepth: _cuticleDepth,
      cuticleLength: _cuticleLength,
      cuticleTone: _cuticleTone,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          imageFile: widget.imageFile,
          zone: zone,
          design: design,
          imageOffset: _imageOffset,
          imageScale: _imageScale,
        ),
      ),
    );
  }

  Widget _buildNailPreview() {
    return SizedBox(
      width: _frameWidth,
      height: _frameHeight,
      child: Stack(
        children: [
          // Ноготь или плейсхолдер — оба по контуру формы
          if (_hasDesign)
            Positioned.fill(
              child: Nail3DRenderer(
                design: _buildCurrentDesign(),
                width: _frameWidth,
                height: _frameHeight,
                showNail: _showNailLayer,
                showCuticle: _showCuticleLayer,
              ),
            )
          else
            Positioned.fill(
              child: CustomPaint(
                painter: _NailFillPainter(
                  shape: _shape,
                  fillColor: Colors.pink.withOpacity(0.1),
                ),
                child: const Center(
                  child: Icon(Icons.touch_app, color: Colors.pink, size: 30),
                ),
              ),
            ),
          // Рамка по контуру ногтя (а не прямоугольник!)
          if (_showFrame)
            Positioned.fill(
              child: CustomPaint(
                painter: _NailOutlinePainter(
                  shape: _shape,
                  color: Colors.pink,
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _groupTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Row(
        children: [
          Icon(icon, color: Colors.pink, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.pink,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow(IconData icon, String label, double value, double min,
      double max, ValueChanged<double> onChanged,
      {int? divisions}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: Colors.pink,
            inactiveColor: Colors.white24,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  /// Кнопка-переключатель режима (3D / Формы / Кутикула)
  Widget _modeButton(String label, int mode, {double width = 70}) {
    return GestureDetector(
      onTap: () => setState(() => _mode = _mode == mode ? 0 : mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: 50,
        decoration: BoxDecoration(
          color: _mode == mode ? Colors.pink : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _mode == mode ? Colors.pink : Colors.white38,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// Строка панели слоёв (крупная, как в фотошопе)
  Widget _layerRow(String name, IconData icon, bool visible, bool? locked,
      VoidCallback onToggleVisible, VoidCallback? onToggleLock) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggleVisible,
            child: Icon(
              visible ? Icons.visibility : Icons.visibility_off,
              color: visible ? Colors.white : Colors.white38,
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 6),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(width: 10),
          if (onToggleLock != null)
            InkWell(
              onTap: onToggleLock,
              child: Icon(
                locked == true ? Icons.lock : Icons.lock_open,
                color: locked == true ? Colors.pink : Colors.white38,
                size: 22,
              ),
            )
          else
            const SizedBox(width: 22),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: const HomeAppBar(
        title: Text('Настройка', style: TextStyle(fontSize: 22)),
      ),
      body: Stack(
        children: [
          // ФОН (фото) — скрывается и блокируется через слой
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: _lockBg ? null : _onPhotoScaleStart,
              onScaleUpdate: _lockBg ? null : _onPhotoScaleUpdate,
              child: _showBgLayer
                  ? Transform.translate(
                      offset: _imageOffset,
                      child: Transform.scale(
                        scale: _imageScale,
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '1 палец — двигать • 2 пальца — зум',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),

          // ПАНЕЛЬ СЛОЁВ (справа): Ноготь / Рамка / Кутикула / Фон
          Positioned(
            top: 120,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _layerRow('Ноготь', Icons.brush, _showNailLayer, _lockNail,
                      () => setState(() => _showNailLayer = !_showNailLayer),
                      () => setState(() => _lockNail = !_lockNail)),
                  _layerRow('Рамка', Icons.border_outer, _showFrame, null,
                      () => setState(() => _showFrame = !_showFrame), null),
                  _layerRow('Кутикула', Icons.water_drop, _showCuticleLayer, null,
                      () => setState(() => _showCuticleLayer = !_showCuticleLayer),
                      null),
                  _layerRow('Фон', Icons.image, _showBgLayer, _lockBg,
                      () => setState(() => _showBgLayer = !_showBgLayer),
                      () => setState(() => _lockBg = !_lockBg)),
                ],
              ),
            ),
          ),

          // НОГОТЬ (рамка) — блокируется через слой
          Positioned(
            left: _frameCenter.dx - _frameWidth / 2,
            top: _frameCenter.dy - _frameHeight / 2,
            child: GestureDetector(
              onPanUpdate: (details) {
                if (_lockNail) return;
                setState(() {
                  _frameCenter += details.delta;
                });
              },
              child: Transform.rotate(
                angle: _rotation * math.pi / 180,
                child: _buildNailPreview(),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ===== ВЕРХНЯЯ СТРОКА: Дизайн + 3D + Формы + Кутикула =====
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openDesignSelection,
                            icon: const Icon(Icons.palette, size: 20),
                            label: Text(
                              _selectedDesign?.color != null
                                  ? _selectedDesign!.color!.name
                                  : 'Выбрать дизайн',
                              style: const TextStyle(fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _modeButton('3D', 1, width: 52),
                        const SizedBox(width: 8),
                        _modeButton('Формы', 3, width: 70),
                        const SizedBox(width: 8),
                        _modeButton('Кутикула', 2, width: 86),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // === РЕЖИМ ФОРМЫ (выбор из 14, выровненные карточки) ===
                    if (_mode == 3) ...[
                      _groupTitle('Форма ногтя', Icons.auto_fix_high),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: NailShape.values.map((shape) {
                            final isSelected = _shape == shape;
                            return GestureDetector(
                              onTap: () => setState(() => _shape = shape),
                              child: Container(
                                width: 80,
                                height: 88,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 6),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected ? Colors.pink : Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomPaint(
                                      size: const Size(30, 40),
                                      painter: _NailShapePreview(shape: shape),
                                    ),
                                    SizedBox(
                                      height: 28,
                                      child: Text(
                                        NailShapeHelper.getName(shape),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    // === РЕЖИМ 3D ===
                    if (_mode == 1) ...[
                      _groupTitle('3D-эффект', Icons.view_in_ar),
                      _sliderRow(Icons.blur_on, 'Объём', _edgeDarken, 0.0, 1.0,
                          (v) => setState(() => _edgeDarken = v)),
                      _sliderRow(Icons.wb_sunny, 'Блик', _highlightIntensity, 0.0,
                          1.0, (v) => setState(() => _highlightIntensity = v)),
                      _sliderRow(Icons.dark_mode, 'Тень', _shadowIntensity, 0.0,
                          1.0, (v) => setState(() => _shadowIntensity = v)),
                    ],

                    // === РЕЖИМ КУТИКУЛА (ЛУНКА) ===
                    if (_mode == 2) ...[
                      _groupTitle('Лунка вокруг ногтя', Icons.water_drop),
                      _sliderRow(Icons.straighten, 'Ширина', _cuticleWidth, 0.0,
                          2.0, (v) => setState(() => _cuticleWidth = v)),
                      _sliderRow(Icons.swap_vert, 'Длина', _cuticleLength, 0.0,
                          1.0, (v) => setState(() => _cuticleLength = v)),
                      _sliderRow(Icons.contrast, 'Темнее', _cuticleDepth, 0.0, 1.0,
                          (v) => setState(() => _cuticleDepth = v)),
                      const SizedBox(height: 4),
                      // Тон кожи: 4 кружка-образца
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(CuticleTones.values.length, (i) {
                          final selected = _cuticleTone == i;
                          return GestureDetector(
                            onTap: () => setState(() => _cuticleTone = i),
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: CuticleTones.values[i],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected ? Colors.white : Colors.white24,
                                  width: selected ? 3 : 1,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],

                    // === БАЗОВЫЙ РЕЖИМ ===
                    if (_mode == 0) ...[
                      // Слои и Яркость — только после выбора дизайна
                      if (_hasDesign) ...[
                        _sliderRow(Icons.layers, 'Слои: ${_density.toInt()}',
                            _density, 1, 3, (v) => setState(() => _density = v),
                            divisions: 2),
                        _sliderRow(Icons.brightness_6, 'Яркость', _brightness,
                            0.7, 1.3, (v) => setState(() => _brightness = v)),
                      ],
                      _sliderRow(Icons.swap_horiz, 'Ширина', _frameWidth, 40, 300,
                          (v) => setState(() => _frameWidth = v)),
                      _sliderRow(Icons.swap_vert, 'Высота', _frameHeight, 40, 400,
                          (v) => setState(() => _frameHeight = v)),
                      _sliderRow(Icons.rotate_right,
                          'Поворот: ${_rotation.toInt()}°', _rotation, -180, 180,
                          (v) => setState(() => _rotation = v)),
                    ],

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveAndNext,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Далее →'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Превью-силуэт формы ногтя в меню выбора.
class _NailShapePreview extends CustomPainter {
  final NailShape shape;
  _NailShapePreview({required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildNailPath(size.width, size.height, shape);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NailShapePreview oldDelegate) =>
      oldDelegate.shape != shape;
}

/// Рамка по контуру ногтя (для острой/сложной формы)
class _NailOutlinePainter extends CustomPainter {
  final NailShape shape;
  final Color color;
  final double strokeWidth;
  _NailOutlinePainter(
      {required this.shape, required this.color, this.strokeWidth = 3});

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildNailPath(size.width, size.height, shape);
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _NailOutlinePainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Заливка плейсхолдера по контуру ногтя
class _NailFillPainter extends CustomPainter {
  final NailShape shape;
  final Color fillColor;
  _NailFillPainter({required this.shape, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildNailPath(size.width, size.height, shape);
    canvas.drawPath(path, Paint()..color = fillColor);
  }

  @override
  bool shouldRepaint(covariant _NailFillPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.fillColor != fillColor;
}