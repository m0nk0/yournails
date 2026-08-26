import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/nail_zone.dart';
import '../models/selected_design.dart';
import '../models/nail_shape.dart';
import '../models/nail_pattern.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/nail_3d_renderer.dart';
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

  // НОВОЕ: показывать ли розовую рамку
  bool _showFrame = true;

  // Раскрыта ли панель тонкой настройки
  bool _showAdvanced = false;

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

  Future<void> _openDesignSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DesignSelectionScreen(
          currentDesign: SelectedDesign(
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
          ),
        ),
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
    final borderRadius = NailShapeHelper.getBorderRadius(_shape, _frameWidth, _frameHeight);

    // НОВОЕ: рамка только если _showFrame
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

    final renderDesign = SelectedDesign(
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
    );

    return Container(
      decoration: BoxDecoration(
        border: frameBorder,
        borderRadius: borderRadius,
      ),
      child: Nail3DRenderer(
        design: renderDesign,
        width: _frameWidth,
        height: _frameHeight,
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

  Widget _buildAdvancedToggle() {
    return InkWell(
      onTap: () => setState(() => _showAdvanced = !_showAdvanced),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tune, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Тонкая настройка',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _showAdvanced ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(
        title: Text('Настройка', style: TextStyle(fontSize: 22)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: _onPhotoScaleStart,
              onScaleUpdate: _onPhotoScaleUpdate,
              child: Transform.translate(
                offset: _imageOffset,
                child: Transform.scale(
                  scale: _imageScale,
                  child: Image.file(
                    widget.imageFile,
                    fit: BoxFit.contain,
                    color: Colors.black.withOpacity(0.3),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
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

          // НОВОЕ: кнопка скрытия рамки (сверху справа, не попадает в фото)
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

          Positioned(
            left: _frameCenter.dx - _frameWidth / 2,
            top: _frameCenter.dy - _frameHeight / 2,
            child: GestureDetector(
              onPanUpdate: (details) {
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openDesignSelection,
                        icon: const Icon(Icons.palette),
                        label: Text(
                          _selectedDesign?.color != null
                              ? 'Дизайн: ${_selectedDesign!.color!.name}'
                              : 'Выбрать дизайн',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                        ),
                      ),
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
                                      border: Border.all(color: Colors.white, width: 2),
                                      borderRadius:
                                          NailShapeHelper.getBorderRadius(shape, 16, 22),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    NailShapeHelper.getName(shape),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight:
                                          isSelected ? FontWeight.bold : FontWeight.normal,
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

                    _buildAdvancedToggle(),

                    if (_showAdvanced) ...[
                      _groupTitle('Цвет', Icons.palette),
                      Row(
                        children: [
                          const Icon(Icons.layers, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 70,
                            child: Text(
                              'Слои: ${_density.toInt()}',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _density,
                              min: 1,
                              max: 3,
                              divisions: 2,
                              activeColor: Colors.pink,
                              inactiveColor: Colors.white24,
                              onChanged: (value) => setState(() => _density = value),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.brightness_6, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 70,
                            child: Text(
                              'Яркость',
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _brightness,
                              min: 0.7,
                              max: 1.3,
                              activeColor: Colors.pink,
                              inactiveColor: Colors.white24,
                              onChanged: (value) => setState(() => _brightness = value),
                            ),
                          ),
                        ],
                      ),

                      _groupTitle('Рамка', Icons.crop),
                      Row(
                        children: [
                          const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          const Text('Ширина',
                              style: TextStyle(color: Colors.white, fontSize: 11)),
                          Expanded(
                            child: Slider(
                              value: _frameWidth,
                              min: 40,
                              max: 300,
                              activeColor: Colors.pink,
                              inactiveColor: Colors.white24,
                              onChanged: (value) => setState(() => _frameWidth = value),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.swap_vert, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          const Text('Высота',
                              style: TextStyle(color: Colors.white, fontSize: 11)),
                          Expanded(
                            child: Slider(
                              value: _frameHeight,
                              min: 40,
                              max: 400,
                              activeColor: Colors.pink,
                              inactiveColor: Colors.white24,
                              onChanged: (value) => setState(() => _frameHeight = value),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.rotate_right, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 70,
                            child: Text(
                              'Поворот: ${_rotation.toInt()}°',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _rotation,
                              min: -180,
                              max: 180,
                              activeColor: Colors.pink,
                              inactiveColor: Colors.white24,
                              onChanged: (value) => setState(() => _rotation = value),
                            ),
                          ),
                        ],
                      ),

                      _groupTitle('3D-эффект', Icons.view_in_ar),
                      Row(
                        children: [
                          const Icon(Icons.blur_on, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 70,
                            child: Text('Объём',
                                style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                          Expanded(
                            child: Slider(
                              value: _edgeDarken,
                              min: 0.0,
                              max: 1.0,
                              activeColor: Colors.pink,
                              inactiveColor: Colors.white24,
                              onChanged: (value) => setState(() => _edgeDarken = value),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.wb_sunny, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 70,
                            child: Text('Блик',
                                style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                          Expanded(
                            child: Slider(
                              value: _highlightIntensity,
                              min: 0.0,
                              max: 1.0,
                              activeColor: Colors.pink,
                              inactiveColor: Colors.white24,
                              onChanged: (value) =>
                                  setState(() => _highlightIntensity = value),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.dark_mode, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 70,
                            child: Text('Тень',
                                style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                          Expanded(
                            child: Slider(
                              value: _shadowIntensity,
                              min: 0.0,
                              max: 1.0,
                              activeColor: Colors.pink,
                              inactiveColor: Colors.white24,
                              onChanged: (value) =>
                                  setState(() => _shadowIntensity = value),
                            ),
                          ),
                        ],
                      ),
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