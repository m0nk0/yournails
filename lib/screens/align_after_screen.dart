import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Экран выравнивания фото "ПОСЛЕ" по прозрачному контуру "ДО"
class AlignAfterScreen extends StatefulWidget {
  final File beforeFile; // призрак (эталон)
  final File afterFile;  // новое фото для выравнивания

  const AlignAfterScreen({
    super.key,
    required this.beforeFile,
    required this.afterFile,
  });

  @override
  State<AlignAfterScreen> createState() => _AlignAfterScreenState();
}

class _AlignAfterScreenState extends State<AlignAfterScreen> {
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _baseScale = 1.0;
  double _ghostOpacity = 0.5;
  bool _isSaving = false;

  void _onScaleStart(ScaleStartDetails d) {
    _baseScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      _offset += d.focalPointDelta;
      _scale = (_baseScale * d.scale).clamp(0.2, 5.0);
    });
  }

  Rect _containRect(Size area, int imgW, int imgH) {
    final s = math.min(area.width / imgW, area.height / imgH);
    final w = imgW * s;
    final h = imgH * s;
    return Rect.fromLTWH((area.width - w) / 2, (area.height - h) / 2, w, h);
  }

  /// Сохранить выровненное фото (возвращает байты PNG)
  Future<void> _saveAligned() async {
    setState(() => _isSaving = true);
    try {
      final beforeBytes = await widget.beforeFile.readAsBytes();
      final bc = Completer<ui.Image>();
      ui.decodeImageFromList(beforeBytes, bc.complete);
      final beforeImg = await bc.future;

      final afterBytes = await widget.afterFile.readAsBytes();
      final ac = Completer<ui.Image>();
      ui.decodeImageFromList(afterBytes, ac.complete);
      final afterImg = await ac.future;

      final mq = MediaQuery.of(context);
      final double W = mq.size.width;
      final double Hh = mq.size.height - mq.padding.top - AppBar().preferredSize.height;
      final areaSize = Size(W, Hh);

      // Эталон (призрак) на экране
      final G = _containRect(areaSize, beforeImg.width, beforeImg.height);
      // Новое фото на экране (contain + зум от центра + смещение)
      final N0 = _containRect(areaSize, afterImg.width, afterImg.height);
      final center = Offset(W / 2, Hh / 2);
      final nTopLeft = Offset(
        center.dx + (N0.left - center.dx) * _scale + _offset.dx,
        center.dy + (N0.top - center.dy) * _scale + _offset.dy,
      );
      final N = Rect.fromLTWH(
          nTopLeft.dx, nTopLeft.dy, N0.width * _scale, N0.height * _scale);

      // Переводим новое фото в пиксельное пространство эталона
      final scaleG = G.width / beforeImg.width;
      final outRect = Rect.fromLTWH(
        (N.left - G.left) / scaleG,
        (N.top - G.top) / scaleG,
        N.width / scaleG,
        N.height / scaleG,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, beforeImg.width.toDouble(), beforeImg.height.toDouble()),
        Paint()..color = const Color(0xFF1a1a1a),
      );
      canvas.drawImageRect(
        afterImg,
        Rect.fromLTWH(0, 0, afterImg.width.toDouble(), afterImg.height.toDouble()),
        outRect,
        Paint(),
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(beforeImg.width, beforeImg.height);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);

      if (mounted) Navigator.pop(context, data!.buffer.asUint8List());
    } catch (e) {
      if (mounted) Navigator.pop(context, null);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Выровнять ПОСЛЕ', style: TextStyle(fontSize: 22)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Новое фото (двигается и зумится)
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: Transform.translate(
                offset: _offset,
                child: Transform.scale(
                  scale: _scale,
                  child: Image.file(widget.afterFile, fit: BoxFit.contain),
                ),
              ),
            ),
          ),

          // Призрак "ДО" поверх
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: _ghostOpacity,
                child: Image.file(widget.beforeFile, fit: BoxFit.contain),
              ),
            ),
          ),

          // Подсказка
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
                  'Двигайте и зумируйте фото под прозрачный контур',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),

          // Панель
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // ИСПРАВЛЕНО: Icons.opacity вместо Icons.ghost
                      const Icon(Icons.opacity, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Прозрачность контура',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Expanded(
                        child: Slider(
                          value: _ghostOpacity,
                          min: 0.1,
                          max: 0.9,
                          activeColor: Colors.pink,
                          inactiveColor: Colors.white24,
                          onChanged: (v) => setState(() => _ghostOpacity = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAligned,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Совпало → Сохранить',
                              style: TextStyle(fontSize: 16)),
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