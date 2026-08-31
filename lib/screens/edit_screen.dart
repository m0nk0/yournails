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

  // Режим панели: 0 = базовый, 1 = 3D, 2 = кутикула
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
        builder: (_) => DesignSelectionScreen(currentDesign: _buildCurrentDesign()),
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
    if (_selectedDesign == null || !_selectedDesign!.hasColor) {
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
    final borderRadius =
        NailShapeHelper.getBorderRadius(_shape, _frameWidth, _frameHeight);
    final frameBorder = _showFrame ? Border.all(color: Colors.pink, width: 3) : null;

    if (_selectedDesign == null || !_selectedDesign!.hasColor) {
      return Container(
        width: _frameWidth,
        height: _frameHeight,
        decoration: BoxDecoration(
          border: frameBorder,
          borderRadius: borderRadius,
          color: Colors.pink.withOpacity(0.1),
        ),
        child: const Center(
          child: Icon(Icons.touch_app, color: Colors.pink, size: 30),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: frameBorder,
        borderRadius: borderRadius,
      ),
      child: Nail3DRenderer(
        design: _buildCurrentDesign(),
        width: _frameWidth,
        height: _frameHeight,
        showNail: _showNailLayer,
        showCuticle: _showCuticleLayer,
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

          // Кнопка скрытия рамки
          Positioned(
            top: 60,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _showFrame = !_showFrame),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    _showFrame ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // ПАНЕЛЬ СЛОЁВ (справа)
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
                        // Кнопка 3D
                        GestureDetector(
                          onTap: () =>
                              setState(() => _mode = _mode == 1 ? 0 : 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _mode == 1 ? Colors.pink : Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _mode == 1 ? Colors.pink : Colors.white38,
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '3D',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Кнопка КУТИКУЛА
                        GestureDetector(
                          onTap: () =>
                              setState(() => _mode = _mode == 2 ? 0 : 2),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 86,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _mode == 2 ? Colors.pink : Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _mode == 2 ? Colors.pink : Colors.white38,
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Кутикула',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: NailShape.values.map((shape) {
                        final isSelected = _shape == shape;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _shape = shape),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.pink : Colors.white10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.white, width: 2),
                                      borderRadius: NailShapeHelper.getBorderRadius(
                                          shape, 16, 22),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    NailShapeHelper.getName(shape),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),

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
                      _sliderRow(Icons.layers, 'Слои: ${_density.toInt()}',
                          _density, 1, 3, (v) => setState(() => _density = v),
                          divisions: 2),
                      _sliderRow(Icons.brightness_6, 'Яркость', _brightness, 0.7,
                          1.3, (v) => setState(() => _brightness = v)),
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