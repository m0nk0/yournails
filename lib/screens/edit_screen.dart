import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/nail_zone.dart';
import '../models/selected_design.dart';
import '../models/nail_shape.dart';
import '../widgets/home_app_bar.dart';
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
            patternPath: _selectedDesign?.patternPath,
            patternName: _selectedDesign?.patternName,
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
      patternPath: _selectedDesign!.patternPath,
      patternName: _selectedDesign!.patternName,
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

    if (_selectedDesign == null || !_selectedDesign!.hasColor) {
      return Container(
        width: _frameWidth,
        height: _frameHeight,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.pink, width: 3),
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
      patternPath: _selectedDesign!.patternPath,
      patternName: _selectedDesign!.patternName,
    );
    final render = renderDesign.getRender();
    final material = _selectedDesign!.material;

    return Container(
      width: _frameWidth,
      height: _frameHeight,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: Colors.pink, width: 3),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: render.opacity,
                child: Container(color: render.color),
              ),
            ),
            if (renderDesign.hasPattern)
              Positioned.fill(
                child: Image.file(
                  File(renderDesign.patternPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            if (material?.hasGloss ?? false)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity((material?.glossIntensity ?? 0.5) * 0.30),
                        Colors.white.withOpacity((material?.glossIntensity ?? 0.5) * 0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.7],
                    ),
                  ),
                ),
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

                    Row(
                      children: [
                        const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        const Text('Ширина', style: TextStyle(color: Colors.white, fontSize: 11)),
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
                        const Text('Высота', style: TextStyle(color: Colors.white, fontSize: 11)),
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
                        const Text('Поворот', style: TextStyle(color: Colors.white, fontSize: 11)),
                        Expanded(
                          child: Slider(
                            value: _rotation,
                            min: 0,
                            max: 360,
                            activeColor: Colors.pink,
                            inactiveColor: Colors.white24,
                            onChanged: (value) => setState(() => _rotation = value),
                          ),
                        ),
                      ],
                    ),

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