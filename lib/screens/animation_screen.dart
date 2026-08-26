import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/nail_session.dart';

enum TransitionType { sparkles, circle, flash, wipe, zoom, slide, fade }
enum VideoTemplate { clean, instagram, tiktok, glam }

class TemplateConfig {
  final String name;
  final String icon;
  final double width;
  final double height;
  final Color bgColor;
  final double borderWidth;
  final Color borderColor;
  final bool labelOnTop;
  final bool labelCenter;
  final Color labelBg;
  final TextStyle labelStyle;
  final bool hasSparkles;

  const TemplateConfig({
    required this.name,
    required this.icon,
    required this.width,
    required this.height,
    required this.bgColor,
    this.borderWidth = 0,
    this.borderColor = Colors.white,
    this.labelOnTop = false,
    this.labelCenter = false,
    required this.labelBg,
    required this.labelStyle,
    this.hasSparkles = false,
  });

  double get aspectRatio => width / height;
}

class VideoTemplates {
  static TemplateConfig get(VideoTemplate t) {
    switch (t) {
      case VideoTemplate.clean:
        return const TemplateConfig(
          name: 'Чистый', icon: '📷',
          width: 480, height: 640,
          bgColor: Color(0xFF1a1a1a),
          labelBg: Color(0xCCe91e63),
          labelStyle: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        );
      case VideoTemplate.instagram:
        return const TemplateConfig(
          name: 'Instagram', icon: '📸',
          width: 640, height: 640,
          bgColor: Colors.white,
          borderWidth: 24, borderColor: Colors.white,
          labelCenter: true, labelBg: Colors.white,
          labelStyle: TextStyle(color: Color(0xFF262626), fontSize: 26,
              fontWeight: FontWeight.w600, letterSpacing: 2),
        );
      case VideoTemplate.tiktok:
        return const TemplateConfig(
          name: 'TikTok', icon: '🎵',
          width: 480, height: 854,
          bgColor: Colors.black,
          labelOnTop: true, labelBg: Colors.black54,
          labelStyle: TextStyle(color: Colors.white, fontSize: 42,
              fontWeight: FontWeight.w900, letterSpacing: 4),
        );
      case VideoTemplate.glam:
        return const TemplateConfig(
          name: 'Гламур', icon: '💎',
          width: 480, height: 640,
          bgColor: Color(0xFF1a1a1a),
          borderWidth: 8, borderColor: Color(0xFFE91E63),
          labelBg: Color(0xFFE91E63),
          labelStyle: TextStyle(color: Colors.white, fontSize: 28,
              fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          hasSparkles: true,
        );
    }
  }
}

class AnimationScreen extends StatefulWidget {
  final NailSession session;
  const AnimationScreen({super.key, required this.session});
  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen>
    with TickerProviderStateMixin {
  List<File> _photoFiles = [];
  List<ui.Image> _images = [];
  List<String> _labels = [];
  AnimationController? _controller;
  TransitionType _transition = TransitionType.sparkles;
  VideoTemplate _template = VideoTemplate.clean;
  bool _isExporting = false;

  final math.Random _rand = math.Random(7);
  late final List<Offset> _seeds = List.generate(
      26, (_) => Offset(_rand.nextDouble(), _rand.nextDouble()));

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

    final images = <ui.Image>[];
    for (final f in files) {
      final bytes = await f.readAsBytes();
      final c = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (i) => c.complete(i));
      images.add(await c.future);
    }

    setState(() {
      _photoFiles = files;
      _images = images;
      _labels = labels;
    });

    if (_images.length >= 2) {
      _controller = AnimationController(
        vsync: this,
        lowerBound: 0,
        upperBound: _images.length.toDouble(),
        duration: Duration(milliseconds: 1500 * _images.length),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void paintFrame(
    Canvas canvas, Size size, double v, {
    required List<ui.Image> images,
    required List<String> labels,
    required TransitionType transition,
    required TemplateConfig tpl,
  }) {
    final n = images.length;
    final idx = v.floor() % n;
    final next = (idx + 1) % n;
    final t = (v - v.floor()).clamp(0.0, 1.0);
    final transT = t < 0.6 ? 0.0 : (t - 0.6) / 0.4;
    final k = size.width / tpl.width;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = tpl.bgColor);

    final b = tpl.borderWidth * k;
    final inner = Rect.fromLTRB(b, b, size.width - b, size.height - b);

    if (tpl.borderWidth > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..color = tpl.borderColor);
    }

    final kenBurns = 1.0 + 0.06 * t;
    _drawContain(canvas, images[idx], inner, 1.0, scale: kenBurns);

    if (transT > 0) {
      switch (transition) {
        case TransitionType.slide:
          _drawContain(canvas, images[next], inner, 1.0,
              dx: (1 - transT) * inner.width);
          break;
        case TransitionType.fade:
          _drawContain(canvas, images[next], inner, transT);
          break;
        case TransitionType.zoom:
          _drawContain(canvas, images[next], inner, math.min(1, transT * 2),
              scale: 1.3 - 0.3 * transT);
          break;
        case TransitionType.wipe:
          canvas.save();
          canvas.clipRect(Rect.fromLTWH(
              inner.left, inner.top, inner.width * transT, inner.height));
          _drawContain(canvas, images[next], inner, 1.0);
          canvas.restore();
          break;
        case TransitionType.circle:
          canvas.save();
          final diag = math.sqrt(
              inner.width * inner.width + inner.height * inner.height);
          canvas.clipPath(Path()
            ..addOval(Rect.fromCircle(
                center: inner.center, radius: transT * diag * 0.6)));
          _drawContain(canvas, images[next], inner, 1.0);
          canvas.restore();
          break;
        case TransitionType.flash:
          _drawContain(canvas, images[next], inner, math.min(1, transT * 1.5));
          final flash = math.sin(transT * math.pi);
          canvas.drawRect(
              inner, Paint()..color = Colors.white.withOpacity(flash * 0.9));
          break;
        case TransitionType.sparkles:
          _drawContain(canvas, images[next], inner, transT);
          _drawSparkles(canvas, inner, transT, k);
          break;
      }
    }

    if (tpl.hasSparkles) _drawCornerSparkles(canvas, size, v, k);

    final tp = TextPainter(
      text: TextSpan(text: labels[idx], style: tpl.labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final ls = tpl.labelStyle.fontSize! * k;
    final padX = 12 * k;
    final padY = 6 * k;
    final boxW = tp.width + padX * 2;
    final boxH = ls + padY * 2;

    double bx, by;
    if (tpl.labelOnTop) {
      bx = (size.width - boxW) / 2;
      by = 16 * k;
    } else if (tpl.labelCenter) {
      bx = (size.width - boxW) / 2;
      by = size.height - b / 2 - boxH / 2;
    } else {
      bx = 16 * k;
      by = size.height - b - boxH - 16 * k;
    }

    canvas.drawRect(Rect.fromLTWH(bx, by, boxW, boxH),
        Paint()..color = tpl.labelBg);
    tp.paint(canvas, Offset(bx + padX, by + padY));
  }

  void _drawSparkles(Canvas canvas, Rect area, double transT, double k) {
    final center = area.center;
    final diag = math.sqrt(area.width * area.width + area.height * area.height);
    for (int i = 0; i < _seeds.length; i++) {
      final s = _seeds[i];
      final angle = s.dx * 2 * math.pi;
      final dist = transT * (0.15 + 0.45 * s.dy) * diag;
      final pos = Offset(center.dx + math.cos(angle) * dist,
          center.dy + math.sin(angle) * dist);
      final alpha = (1 - transT).clamp(0.0, 1.0);
      final r = (2 + 6 * s.dy) * k;
      canvas.drawCircle(pos, r,
          Paint()..color = Colors.white.withOpacity(alpha * 0.9));
      canvas.drawLine(Offset(pos.dx - r * 2, pos.dy),
          Offset(pos.dx + r * 2, pos.dy),
          Paint()..color = Colors.white.withOpacity(alpha * 0.5)
            ..strokeWidth = 1 * k);
      canvas.drawLine(Offset(pos.dx, pos.dy - r * 2),
          Offset(pos.dx, pos.dy + r * 2),
          Paint()..color = Colors.white.withOpacity(alpha * 0.5)
            ..strokeWidth = 1 * k);
    }
  }

  void _drawCornerSparkles(Canvas canvas, Size size, double v, double k) {
    for (int i = 0; i < 4; i++) {
      final tw = 0.5 + 0.5 * math.sin(v * 2 * math.pi + i * 1.7);
      final tp = TextPainter(
        text: TextSpan(text: '✨',
            style: TextStyle(fontSize: (20 + 8 * tw) * k)),
        textDirection: TextDirection.ltr,
      )..layout();
      final m = 12 * k;
      final positions = [
        Offset(m, m),
        Offset(size.width - tp.width - m, m),
        Offset(m, size.height - tp.height - m),
        Offset(size.width - tp.width - m, size.height - tp.height - m),
      ];
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
      tp.paint(canvas, positions[i]);
      canvas.restore();
    }
  }

  void _drawContain(Canvas canvas, ui.Image image, Rect area, double opacity,
      {double dx = 0, double scale = 1.0}) {
    final s = math.min(area.width / image.width, area.height / image.height) * scale;
    final w = image.width * s;
    final h = image.height * s;
    final rect = Rect.fromLTWH(
      area.left + (area.width - w) / 2 + dx,
      area.top + (area.height - h) / 2,
      w, h,
    );
    canvas.save();
    canvas.clipRect(area);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      Paint()..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0, 1)),
    );
    canvas.restore();
  }

  Future<void> _exportGif({bool toGallery = false}) async {
    if (_images.length < 2 || _isExporting) return;
    setState(() => _isExporting = true);

    try {
      final tpl = VideoTemplates.get(_template);
      final W = tpl.width;
      final H = tpl.height;
      const int fps = 10;
      const double segSec = 1.5;
      final int framesPerSeg = (fps * segSec).round();

      final encoder = img.GifEncoder();

      for (int seg = 0; seg < _images.length; seg++) {
        for (int f = 0; f < framesPerSeg; f++) {
          final v = seg + f / framesPerSeg;

          await Future.delayed(const Duration(milliseconds: 5));

          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          paintFrame(canvas, Size(W, H), v,
              images: _images,
              labels: _labels,
              transition: _transition,
              tpl: tpl);

          final picture = recorder.endRecording();
          final uiImage = await picture.toImage(W.toInt(), H.toInt());
          final pngBytes =
              await uiImage.toByteData(format: ui.ImageByteFormat.png);
          final frame = img.decodePng(pngBytes!.buffer.asUint8List());
          if (frame != null) encoder.addFrame(frame, duration: 1000 ~/ fps);
        }
      }

      final gifBytes = encoder.finish();
      if (gifBytes == null) throw Exception('Не удалось создать GIF');

      final tempDir = await getTemporaryDirectory();
      final gifFile = File(
          '${tempDir.path}/yournails_${DateTime.now().millisecondsSinceEpoch}.gif');
      await gifFile.writeAsBytes(gifBytes);

      if (mounted) {
        if (toGallery) {
          await Gal.putImage(gifFile.path);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GIF сохранён в галерею'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
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
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tpl = VideoTemplates.get(_template);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Видео до/после', style: TextStyle(fontSize: 22)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _images.length < 2
          ? const Center(
              child: Text('Нужно минимум 2 фото в визите',
                  style: TextStyle(color: Colors.white, fontSize: 18)))
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: tpl.aspectRatio,
                      child: _controller == null
                          ? const SizedBox()
                          : AnimatedBuilder(
                              animation: _controller!,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: _FramePainter(
                                      state: this, v: _controller!.value),
                                );
                              },
                            ),
                    ),
                  ),
                ),
                Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: TransitionType.values.map((tr) {
                            final isSelected = _transition == tr;
                            final names = {
                              TransitionType.sparkles: '✨ Блёстки',
                              TransitionType.circle: '⭕ Круг',
                              TransitionType.flash: '⚡ Вспышка',
                              TransitionType.wipe: '🎭 Шторка',
                              TransitionType.zoom: '🎯 Зум',
                              TransitionType.slide: '📱 Слайд',
                              TransitionType.fade: '🌫 Фейд',
                            };
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(names[tr]!),
                                selected: isSelected,
                                onSelected: (_) =>
                                    setState(() => _transition = tr),
                                backgroundColor: Colors.white10,
                                selectedColor: Colors.pink,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[300],
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: VideoTemplate.values.map((t) {
                          final isSelected = _template == t;
                          final cfg = VideoTemplates.get(t);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: ChoiceChip(
                                label: Text('${cfg.icon} ${cfg.name}'),
                                selected: isSelected,
                                onSelected: (_) =>
                                    setState(() => _template = t),
                                backgroundColor: Colors.white10,
                                selectedColor: Colors.pink,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[300],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isExporting
                                  ? null
                                  : () => _exportGif(toGallery: true),
                              icon: _isExporting
                                  ? const SizedBox(
                                      width: 16, height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.download, size: 20),
                              label: const Text('В галерею',
                                  style: TextStyle(fontSize: 14)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isExporting ? null : () => _exportGif(),
                              icon: const Icon(Icons.share, size: 20),
                              label: const Text('Отправить GIF',
                                  style: TextStyle(fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _FramePainter extends CustomPainter {
  final _AnimationScreenState state;
  final double v;
  _FramePainter({required this.state, required this.v});

  @override
  void paint(Canvas canvas, Size size) {
    state.paintFrame(canvas, size, v,
        images: state._images,
        labels: state._labels,
        transition: state._transition,
        tpl: VideoTemplates.get(state._template));
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) => true;
}