import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/nail_session.dart';

/// Типы переходов
enum TransitionType { slide, fade, zoom }

/// Анимация "было/стало" (до → примерка → после)
class AnimationScreen extends StatefulWidget {
  final NailSession session;

  const AnimationScreen({super.key, required this.session});

  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen>
    with SingleTickerProviderStateMixin {
  List<File> _photos = [];
  List<String> _labels = [];
  AnimationController? _controller;
  TransitionType _transition = TransitionType.slide;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final files = <File>[];
    final labels = <String>[];

    if (widget.session.hasBefore) {
      files.add(File(widget.session.beforePhotoPath!));
      labels.add('ДО');
    }
    if (widget.session.hasTryOn) {
      files.add(File(widget.session.tryOnPhotoPath!));
      labels.add('ПРИМЕРКА');
    }
    if (widget.session.hasAfter) {
      files.add(File(widget.session.afterPhotoPath!));
      labels.add('ПОСЛЕ');
    }

    setState(() {
      _photos = files;
      _labels = labels;
    });

    if (files.length >= 2) {
      _controller = AnimationController(
        vsync: this,
        lowerBound: 0,
        upperBound: files.length.toDouble(),
        duration: Duration(milliseconds: 1500 * files.length),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Экспорт в GIF
  Future<void> _exportGif() async {
    if (_photos.length < 2 || _isExporting) return;
    setState(() => _isExporting = true);

    try {
      const double W = 480.0;
      const double H = 640.0;
      const int fps = 10;
      const double segSec = 1.5;
      final int framesPerSeg = (fps * segSec).round();

      final images = <ui.Image>[];
      for (final f in _photos) {
        final bytes = await f.readAsBytes();
        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(bytes, (image) => completer.complete(image));
        images.add(await completer.future);
      }

      final encoder = img.GifEncoder();

      for (int seg = 0; seg < images.length; seg++) {
        final next = (seg + 1) % images.length;
        for (int f = 0; f < framesPerSeg; f++) {
          final t = f / framesPerSeg;
          final transT = t < 0.6 ? 0.0 : (t - 0.6) / 0.4;

          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);

          // Фон
          canvas.drawRect(
            Rect.fromLTWH(0, 0, W, H),
            Paint()..color = const Color(0xFF1a1a1a),
          );

          // Текущее фото
          _drawContain(canvas, images[seg], Size(W, H), 1.0);

          // Переход к следующему
          if (transT > 0) {
            if (_transition == TransitionType.slide) {
              _drawContain(
                canvas,
                images[next],
                Size(W, H),
                1.0,
                dx: (1 - transT) * W,
              );
            } else if (_transition == TransitionType.fade) {
              _drawContain(canvas, images[next], Size(W, H), transT);
            } else {
              _drawContain(
                canvas,
                images[next],
                Size(W, H),
                transT,
                scale: 0.8 + 0.2 * transT,
              );
            }
          }

          // Подпись
          final label = _labels[seg];
          final tp = TextPainter(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          canvas.drawRect(
            Rect.fromLTWH(16, H - 52, tp.width + 24, 40),
            Paint()..color = const Color(0xCCe91e63),
          );
          tp.paint(canvas, const Offset(28, H - 46));

          final picture = recorder.endRecording();
          final uiImage = await picture.toImage(W.toInt(), H.toInt());

          // ИСПРАВЛЕНО: PNG формат вместо rawRgba8888
          final pngBytes =
              await uiImage.toByteData(format: ui.ImageByteFormat.png);
          final frame = img.decodePng(pngBytes!.buffer.asUint8List());

          if (frame != null) {
            encoder.addFrame(frame, duration: 1000 ~/ fps);
          }
        }
      }

      final gifBytes = encoder.finish();
      if (gifBytes == null) throw Exception('Не удалось создать GIF');

      final tempDir = await getTemporaryDirectory();
      final gifFile = File(
          '${tempDir.path}/yournails_${DateTime.now().millisecondsSinceEpoch}.gif');
      await gifFile.writeAsBytes(gifBytes);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(gifFile.path)],
          text: 'Моя работа 💅 до и после',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GIF готов и отправлен'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  /// Нарисовать изображение с центрированием (contain)
  void _drawContain(
    Canvas canvas,
    ui.Image image,
    Size size,
    double opacity, {
    double dx = 0,
    double scale = 1.0,
  }) {
    final s = math.min(size.width / image.width, size.height / image.height);
    final w = image.width * s * scale;
    final h = image.height * s * scale;
    final rect = Rect.fromLTWH(
      (size.width - w) / 2 + dx,
      (size.height - h) / 2,
      w,
      h,
    );
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      Paint()..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0, 1)),
    );
    canvas.restore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Анимация до/после', style: TextStyle(fontSize: 22)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share, size: 28),
            tooltip: 'Сохранить GIF',
            onPressed: _isExporting ? null : _exportGif,
          ),
        ],
      ),
      body: _photos.length < 2
          ? const Center(
              child: Text(
                'Нужно минимум 2 фото в визите',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : Column(
              children: [
                // Область анимации
                Expanded(
                  child: AnimatedBuilder(
                    animation: _controller!,
                    builder: (context, child) {
                      final v = _controller!.value;
                      final n = _photos.length;
                      final idx = v.floor() % n;
                      final next = (idx + 1) % n;
                      final t = v - v.floor();
                      final transT = t < 0.6 ? 0.0 : (t - 0.6) / 0.4;

                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Image.file(_photos[idx], fit: BoxFit.contain),
                          ),
                          if (transT > 0 && _transition == TransitionType.slide)
                            Positioned.fill(
                              child: FractionalTranslation(
                                translation: Offset(1 - transT, 0),
                                child: Image.file(
                                  _photos[next],
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          if (transT > 0 && _transition == TransitionType.fade)
                            Positioned.fill(
                              child: Opacity(
                                opacity: transT,
                                child: Image.file(
                                  _photos[next],
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          if (transT > 0 && _transition == TransitionType.zoom)
                            Positioned.fill(
                              child: Opacity(
                                opacity: transT,
                                child: Transform.scale(
                                  scale: 0.8 + 0.2 * transT,
                                  child: Image.file(
                                    _photos[next],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          // Подпись
                          Positioned(
                            left: 16,
                            bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              color: const Color(0xCCe91e63),
                              child: Text(
                                _labels[idx],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Панель выбора перехода
                Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: TransitionType.values.map((tr) {
                      final isSelected = _transition == tr;
                      final name = tr == TransitionType.slide
                          ? 'Слайд'
                          : tr == TransitionType.fade
                              ? 'Фейд'
                              : 'Зум';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(name),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _transition = tr),
                          backgroundColor: Colors.white10,
                          selectedColor: Colors.pink,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}