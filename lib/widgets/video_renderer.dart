import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/master_icons.dart';
import '../models/master.dart';
enum TransitionType { sparkles, circle, flash, wipe, zoom, slide, fade }

enum VideoTemplate {
  // === ТРЕНДЫ ===
  splitScreen,
  reveal,
  magazine,
  reels,
  cinematic,
  // === КЛАССИКА ===
  clean,
  instagram,
  tiktok,
  glam,
}

class TemplateConfig {
  final String name;
  final String icon;
  final double width;
  final double height;
  final Color bgColor;
  final double borderWidth;
  final Color borderColor;
  final Color labelBg;
  final TextStyle labelStyle;
  final bool hasSparkles;
  final bool isSplitScreen;
  final bool isReveal;
  final bool isMagazine;
  final bool isReels;
  final bool isCinematic;
  /// Высота чёрных полос сверху/снизу (только для cinematic)
  final double letterboxHeight;
  /// Интенсивность зернистости 0..1 (только для cinematic)
  final double grainIntensity;

  const TemplateConfig({
    required this.name,
    required this.icon,
    required this.width,
    required this.height,
    required this.bgColor,
    this.borderWidth = 0,
    this.borderColor = Colors.white,
    required this.labelBg,
    required this.labelStyle,
    this.hasSparkles = false,
    this.isSplitScreen = false,
    this.isReveal = false,
    this.isMagazine = false,
    this.isReels = false,
    this.isCinematic = false,
    this.letterboxHeight = 0,
    this.grainIntensity = 0,
  });

  double get aspectRatio => width / height;

  /// Строковое имя для сохранения в settings
  String get id {
    for (final t in VideoTemplate.values) {
      if (VideoTemplates.get(t) == this) {
        return t.name;
      }
    }
    return name;
  }
}

class VideoTemplates {
  static TemplateConfig get(VideoTemplate t) {
    switch (t) {
      // === ТРЕНДЫ ===
      case VideoTemplate.splitScreen:
        return const TemplateConfig(
          name: 'Слайдер',
          icon: '🎚',
          width: 1080,
          height: 1920,
          bgColor: Colors.black,
          labelBg: Color(0xFFE91E63),
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
          isSplitScreen: true,
        );

      case VideoTemplate.reveal:
        return const TemplateConfig(
          name: 'Вспышка',
          icon: '⚡',
          width: 1080,
          height: 1920,
          bgColor: Colors.black,
          labelBg: Color(0xFFE91E63),
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 12),
            ],
          ),
          isReveal: true,
        );

      case VideoTemplate.magazine:
        return const TemplateConfig(
          name: 'Обложка',
          icon: '📰',
          width: 1080,
          height: 1920,
          bgColor: Color(0xFFFAF7F2),
          labelBg: Color(0xFFE91E63),
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
          isMagazine: true,
        );

      // === НОВОЕ: REELS — вертикальный формат для TikTok/Instagram Reels ===
      case VideoTemplate.reels:
        return const TemplateConfig(
          name: 'Reels',
          icon: '🎬',
          width: 1080,
          height: 1920,
          bgColor: Colors.black,
          borderWidth: 0,
          labelBg: Color(0xFFE91E63),
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 18),
              Shadow(color: Colors.black, blurRadius: 4),
            ],
          ),
          isReels: true,
        );

      // === НОВОЕ: CINEMATIC — широкоэкранный 16:9 с letterbox + зерно ===
      case VideoTemplate.cinematic:
        return const TemplateConfig(
          name: 'Кино',
          icon: '🎞',
          width: 1920,
          height: 1080,
          bgColor: Colors.black,
          borderWidth: 0,
          labelBg: Color(0xFFE91E63),
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 12),
            ],
          ),
          isCinematic: true,
          letterboxHeight: 140,
          grainIntensity: 0.10,
        );

      // === КЛАССИКА ===
      case VideoTemplate.clean:
        return const TemplateConfig(
          name: 'Чистый',
          icon: '📷',
          width: 480,
          height: 640,
          bgColor: Color(0xFF1a1a1a),
          labelBg: Color(0xCCe91e63),
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        );
      case VideoTemplate.instagram:
        return const TemplateConfig(
          name: 'Instagram',
          icon: '📸',
          width: 640,
          height: 640,
          bgColor: Colors.white,
          borderWidth: 24,
          borderColor: Colors.white,
          labelBg: Colors.white,
          labelStyle: TextStyle(
            color: Color(0xFF262626),
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        );
      case VideoTemplate.tiktok:
        return const TemplateConfig(
          name: 'TikTok',
          icon: '🎵',
          width: 480,
          height: 854,
          bgColor: Colors.black,
          labelBg: Colors.black54,
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        );
      case VideoTemplate.glam:
        return const TemplateConfig(
          name: 'Гламур',
          icon: '💎',
          width: 480,
          height: 640,
          bgColor: Color(0xFF1a1a1a),
          borderWidth: 8,
          borderColor: Color(0xFFE91E63),
          labelBg: Color(0xFFE91E63),
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
          hasSparkles: true,
        );
    }
  }

  /// Парсит шаблон из строки (для восстановления из settings)
  static VideoTemplate fromString(String? name) {
    if (name == null) return VideoTemplate.splitScreen;
    for (final t in VideoTemplate.values) {
      if (t.name == name) return t;
    }
    return VideoTemplate.splitScreen;
  }
}

class VideoRenderer {
  static void paintFrame(
    Canvas canvas,
    Size size,
    double v, {
    required List<ui.Image> images,
    required List<String> labels,
    required TransitionType transition,
    required TemplateConfig tpl,
    Master? master,
    ui.Image? masterLogoImage,
  }) {
    final math.Random rand = math.Random(7);
    final List<Offset> seeds =
        List.generate(26, (_) => Offset(rand.nextDouble(), rand.nextDouble()));

    _paintFrame(canvas, size, v,
        images: images,
        labels: labels,
        transition: transition,
        tpl: tpl,
        seeds: seeds,
        master: master,
        masterLogoImage: masterLogoImage);
  }

  /// [cancelChecker] — функция, возвращающая true, если пользователь отменил рендер.
  /// Вызывается перед каждым кадром. Если возвращает true — рендер прерывается,
  /// временный файл удаляется, возвращается null.
  static Future<String?> renderVideo({
    required List<ui.Image> images,
    required List<String> labels,
    required VideoTemplate template,
    required TransitionType transition,
    Master? master,
    ui.Image? masterLogoImage,
    double segmentDurationSec = 1.5,
    int fps = 30,
    Function(double)? onProgress,
    bool Function()? cancelChecker,
  }) async {
    if (images.length < 2) return null;

    final tpl = VideoTemplates.get(template);
    final width = tpl.width.toInt();
    final height = tpl.height.toInt();
    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/yournails_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final int segments =
        tpl.isSplitScreen ? images.length - 1 : images.length;
    final double segDur = tpl.isSplitScreen ? 2.5 : segmentDurationSec;

    try {
      await FlutterQuickVideoEncoder.setup(
        width: width,
        height: height,
        fps: fps,
        videoBitrate: 2500000,
        profileLevel: ProfileLevel.any,
        audioBitrate: 0,
        audioChannels: 0,
        sampleRate: 0,
        filepath: outputPath,
      );

      final int framesPerSegment = (fps * segDur).round();
      final int totalFrames = framesPerSegment * segments;
      final math.Random rand = math.Random(7);
      final List<Offset> seeds =
          List.generate(26, (_) => Offset(rand.nextDouble(), rand.nextDouble()));

      for (int seg = 0; seg < segments; seg++) {
        for (int f = 0; f < framesPerSegment; f++) {
          // Проверка отмены перед каждым кадром
          if (cancelChecker != null && cancelChecker()) {
            await FlutterQuickVideoEncoder.finish();
            // Удаляем незавершённый файл
            final file = File(outputPath);
            if (await file.exists()) await file.delete();
            return null;
          }

          final v = seg + f / framesPerSegment;

          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);

          _paintFrame(canvas, Size(width.toDouble(), height.toDouble()), v,
              images: images,
              labels: labels,
              transition: transition,
              tpl: tpl,
              seeds: seeds,
              master: master,
              masterLogoImage: masterLogoImage);

          final picture = recorder.endRecording();
          final uiImage = await picture.toImage(width, height);
          final byteData =
              await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);

          if (byteData != null) {
            await FlutterQuickVideoEncoder.appendVideoFrame(
                byteData.buffer.asUint8List());
          }

          if (onProgress != null) {
            onProgress((seg * framesPerSegment + f) / totalFrames);
          }
        }
      }

      await FlutterQuickVideoEncoder.finish();
      return outputPath;
    } catch (e) {
      print('Ошибка рендеринга видео: $e');
      // Чистим битый файл
      try {
        final file = File(outputPath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      return null;
    }
  }

  static void _paintFrame(
    Canvas canvas,
    Size size,
    double v, {
    required List<ui.Image> images,
    required List<String> labels,
    required TransitionType transition,
    required TemplateConfig tpl,
    required List<Offset> seeds,
    Master? master,
    ui.Image? masterLogoImage,
  }) {
    // === SPLIT-SCREEN SLIDER ===
    if (tpl.isSplitScreen) {
      _paintSplitScreen(canvas, size, v,
          images: images,
          labels: labels,
          tpl: tpl,
          master: master,
          masterLogoImage: masterLogoImage);
      return;
    }

    // === REVEAL / ВСПЫШКА (ВИРУСНЫЙ) ===
    if (tpl.isReveal) {
      _paintReveal(canvas, size, v,
          images: images,
          labels: labels,
          tpl: tpl,
          master: master,
          masterLogoImage: masterLogoImage);
      return;
    }

    // === MAGAZINE (ОБЛОЖКА ЖУРНАЛА) ===
    if (tpl.isMagazine) {
      _paintMagazine(canvas, size, v,
          images: images,
          labels: labels,
          tpl: tpl,
          master: master,
          masterLogoImage: masterLogoImage);
      return;
    }

    // === REELS — вертикальный формат с крупной типографикой ===
    if (tpl.isReels) {
      _paintReels(canvas, size, v,
          images: images,
          labels: labels,
          tpl: tpl,
          transition: transition,
          seeds: seeds,
          master: master,
          masterLogoImage: masterLogoImage);
      return;
    }

    // === CINEMATIC — широкоэкранный с letterbox и зерном ===
    if (tpl.isCinematic) {
      _paintCinematic(canvas, size, v,
          images: images,
          labels: labels,
          tpl: tpl,
          transition: transition,
          seeds: seeds,
          master: master,
          masterLogoImage: masterLogoImage);
      return;
    }

    // === ОБЫЧНЫЕ ШАБЛОНЫ ===
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
          _drawSparkles(canvas, inner, transT, k, seeds);
          break;
      }
    }

    // ===== НАДПИСЬ (ДО / ПРИМЕРКА / ПОСЛЕ) — ВВЕРХ ПО ЦЕНТРУ =====
    final tp = TextPainter(
      text: TextSpan(text: labels[idx], style: tpl.labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final ls = tpl.labelStyle.fontSize! * k;
    final padX = 12 * k;
    final padY = 6 * k;
    final boxW = tp.width + padX * 2;
    final boxH = ls + padY * 2;
    final lx = (size.width - boxW) / 2;
    final ly = b + 16 * k;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(lx, ly, boxW, boxH), Radius.circular(10 * k)),
      Paint()..color = tpl.labelBg,
    );
    tp.paint(canvas, Offset(lx + padX, ly + padY));

    // ===== БЛОК МАСТЕРА — ВНИЗ ПО ЦЕНТРУ =====
    if (master != null) {
      _drawMasterBadge(canvas, size, k, b, master, masterLogoImage);
    }

    if (tpl.hasSparkles) _drawCornerSparkles(canvas, size, v, k);
  }

  // === REELS — вертикальный формат для TikTok/Instagram Reels ===
  // Фото cover-кропом на весь экран, жирный заголовок "ДО" / "ПОСЛЕ"
  // по центру, розовая рамка, мастер внизу.
  static void _paintReels(
    Canvas canvas,
    Size size,
    double v, {
    required List<ui.Image> images,
    required List<String> labels,
    required TemplateConfig tpl,
    required TransitionType transition,
    required List<Offset> seeds,
    Master? master,
    ui.Image? masterLogoImage,
  }) {
    final n = images.length;
    final idx = v.floor() % n;
    final next = (idx + 1) % n;
    final t = (v - v.floor()).clamp(0.0, 1.0);
    final transT = t < 0.55 ? 0.0 : (t - 0.55) / 0.45;
    final k = size.width / tpl.width;

    // Чёрный фон
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.black);

    // Фото cover-кропом с Ken Burns
    final kenBurns = 1.0 + 0.07 * t;
    _drawCover(canvas, images[idx],
        Rect.fromLTWH(0, 0, size.width, size.height), 1.0,
        scale: kenBurns);

    if (transT > 0) {
      switch (transition) {
        case TransitionType.fade:
          _drawCover(canvas, images[next],
              Rect.fromLTWH(0, 0, size.width, size.height), transT,
              scale: 1.0);
          break;
        case TransitionType.wipe:
          canvas.save();
          canvas.clipRect(Rect.fromLTWH(
              0, 0, size.width * transT, size.height));
          _drawCover(canvas, images[next],
              Rect.fromLTWH(0, 0, size.width, size.height), 1.0,
              scale: 1.0);
          canvas.restore();
          break;
        case TransitionType.zoom:
          _drawCover(canvas, images[next],
              Rect.fromLTWH(0, 0, size.width, size.height),
              math.min(1, transT * 2),
              scale: 1.3 - 0.3 * transT);
          break;
        case TransitionType.flash:
          _drawCover(canvas, images[next],
              Rect.fromLTWH(0, 0, size.width, size.height),
              math.min(1, transT * 1.5),
              scale: 1.0);
          final flash = math.sin(transT * math.pi);
          canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
              Paint()..color = Colors.white.withOpacity(flash * 0.9));
          break;
        case TransitionType.slide:
          canvas.save();
          canvas.clipRect(Rect.fromLTWH(
              (1 - transT) * size.width, 0, size.width, size.height));
          _drawCover(canvas, images[next],
              Rect.fromLTWH(0, 0, size.width, size.height), 1.0,
              scale: 1.0);
          canvas.restore();
          break;
        case TransitionType.circle:
          canvas.save();
          final diag = math.sqrt(size.width * size.width + size.height * size.height);
          canvas.clipPath(Path()
            ..addOval(Rect.fromCircle(
                center: Offset(size.width / 2, size.height / 2),
                radius: transT * diag * 0.6)));
          _drawCover(canvas, images[next],
              Rect.fromLTWH(0, 0, size.width, size.height), 1.0,
              scale: 1.0);
          canvas.restore();
          break;
        case TransitionType.sparkles:
          _drawCover(canvas, images[next],
              Rect.fromLTWH(0, 0, size.width, size.height), transT,
              scale: 1.0);
          _drawSparkles(canvas,
              Rect.fromLTWH(0, 0, size.width, size.height), transT, k, seeds);
          break;
      }
    }

    // Розовая рамка поверх
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = const Color(0xFFE91E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 * k,
    );

    // === ОГРОМНЫЙ ЗАГОЛОВОК ПО ЦЕНТРУ ===
    final tp = TextPainter(
      text: TextSpan(text: labels[idx], style: tpl.labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final lx = (size.width - tp.width) / 2;
    final ly = (size.height - tp.height) / 2;

    // Тёмная подложка для читаемости
    final padX = 40 * k;
    final padY = 20 * k;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(
              lx - padX, ly - padY, tp.width + padX * 2, tp.height + padY * 2),
          Radius.circular(24 * k)),
      Paint()..color = Colors.black.withOpacity(0.55),
    );
    tp.paint(canvas, Offset(lx, ly));

    // Мастер внизу (в зоне safe area)
    if (master != null) {
      _drawMasterBadge(canvas, size, k, 0, master, masterLogoImage);
    }
  }

  // === CINEMATIC — широкоэкранный 16:9 с letterbox и зерном ===
  // Чёрные полосы сверху/снизу, фото в центре, grain overlay,
  // мастер-бейдж в правой нижней "безопасной" зоне.
  static void _paintCinematic(
    Canvas canvas,
    Size size,
    double v, {
    required List<ui.Image> images,
    required List<String> labels,
    required TemplateConfig tpl,
    required TransitionType transition,
    required List<Offset> seeds,
    Master? master,
    ui.Image? masterLogoImage,
  }) {
    final n = images.length;
    final idx = v.floor() % n;
    final next = (idx + 1) % n;
    final t = (v - v.floor()).clamp(0.0, 1.0);
    final transT = t < 0.6 ? 0.0 : (t - 0.6) / 0.4;
    final k = size.width / tpl.width;

    final letterboxH = tpl.letterboxHeight * k;

    // Чёрный фон (letterbox)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.black);

    // Область изображения (между чёрными полосами)
    final inner = Rect.fromLTRB(0, letterboxH, size.width,
        size.height - letterboxH);

    // Фото с Ken Burns
    final kenBurns = 1.0 + 0.05 * t;
    _drawCover(canvas, images[idx], inner, 1.0, scale: kenBurns);

    if (transT > 0) {
      switch (transition) {
        case TransitionType.fade:
          _drawCover(canvas, images[next], inner, transT, scale: 1.0);
          break;
        case TransitionType.wipe:
          canvas.save();
          canvas.clipRect(
              Rect.fromLTWH(inner.left, inner.top, inner.width * transT, inner.height));
          _drawCover(canvas, images[next], inner, 1.0, scale: 1.0);
          canvas.restore();
          break;
        case TransitionType.zoom:
          _drawCover(canvas, images[next], inner, math.min(1, transT * 2),
              scale: 1.3 - 0.3 * transT);
          break;
        case TransitionType.flash:
          _drawCover(canvas, images[next], inner, math.min(1, transT * 1.5),
              scale: 1.0);
          final flash = math.sin(transT * math.pi);
          canvas.drawRect(inner,
              Paint()..color = Colors.white.withOpacity(flash * 0.9));
          break;
        case TransitionType.slide:
          canvas.save();
          canvas.clipRect(Rect.fromLTWH(
              inner.left + (1 - transT) * inner.width,
              inner.top,
              inner.width * transT,
              inner.height));
          _drawCover(canvas, images[next], inner, 1.0, scale: 1.0);
          canvas.restore();
          break;
        case TransitionType.circle:
          canvas.save();
          final diag = math.sqrt(inner.width * inner.width + inner.height * inner.height);
          canvas.clipPath(Path()
            ..addOval(Rect.fromCircle(
                center: inner.center, radius: transT * diag * 0.6)));
          _drawCover(canvas, images[next], inner, 1.0, scale: 1.0);
          canvas.restore();
          break;
        case TransitionType.sparkles:
          _drawCover(canvas, images[next], inner, transT, scale: 1.0);
          _drawSparkles(canvas, inner, transT, k, seeds);
          break;
      }
    }

    // === ЗЕРНО (псевдослучайные точки по всей площади изображения) ===
    if (tpl.grainIntensity > 0) {
      final grainRand = math.Random(17);
      final grainCount = (size.width * size.height * 0.00008).toInt();
      final grainPaint = Paint();
      for (int i = 0; i < grainCount; i++) {
        final x = grainRand.nextDouble() * size.width;
        final y = letterboxH + grainRand.nextDouble() * inner.height;
        final brightness = grainRand.nextDouble() < 0.5 ? 255 : 0;
        final a = tpl.grainIntensity * (0.4 + grainRand.nextDouble() * 0.6);
        grainPaint.color = Color.fromARGB((a * 255).round(), brightness, brightness, brightness);
        canvas.drawCircle(Offset(x, y), 1.2 * k, grainPaint);
      }
    }

    // === НАДПИСЬ ПО ЦЕНТРУ ВЕРХНЕЙ LETTERBOX-ПОЛОСЫ ===
    final tp = TextPainter(
      text: TextSpan(text: labels[idx], style: tpl.labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset((size.width - tp.width) / 2,
            (letterboxH - tp.height) / 2));

    // Мастер внизу справа (safe area внутри изображения)
    if (master != null) {
      _drawMasterBadge(canvas, size, k, letterboxH, master, masterLogoImage);
    }
  }

  // === SPLIT-SCREEN SLIDER ===
  static void _paintSplitScreen(
    Canvas canvas,
    Size size,
    double v, {
    required List<ui.Image> images,
    required List<String> labels,
    required TemplateConfig tpl,
    Master? master,
    ui.Image? masterLogoImage,
  }) {
    final n = images.length;
    final maxSeg = n - 2;
    final seg = v.floor().clamp(0, maxSeg);
    final t = (v - v.floor()).clamp(0.0, 1.0);
    final k = size.width / tpl.width;

    final beforeImg = images[seg];
    final afterImg = images[seg + 1];
    final beforeLabel = labels[seg];
    final afterLabel = labels[seg + 1];

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = tpl.bgColor);

    final sliderProgress = _easeInOut(t);
    final splitX = sliderProgress * size.width;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, splitX, size.height));
    _drawContain(canvas, afterImg,
        Rect.fromLTWH(0, 0, size.width, size.height), 1.0);
    canvas.restore();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(splitX, 0, size.width - splitX, size.height));
    _drawContain(canvas, beforeImg,
        Rect.fromLTWH(0, 0, size.width, size.height), 1.0);
    canvas.restore();

    const pink = Color(0xFFE91E63);
    final lineWidth = 4 * k;
    final glowPaint = Paint()
      ..color = pink.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRect(
        Rect.fromLTWH(splitX - lineWidth / 2, 0, lineWidth, size.height),
        glowPaint);
    canvas.drawRect(
        Rect.fromLTWH(splitX - lineWidth / 2, 0, lineWidth, size.height),
        Paint()..color = pink);

    final circleY = size.height / 2;
    final circleR = 32 * k;
    canvas.drawCircle(Offset(splitX, circleY), circleR + 4 * k,
        Paint()..color = Colors.white.withOpacity(0.9));
    canvas.drawCircle(Offset(splitX, circleY), circleR, Paint()..color = pink);

    final arrowSize = 12 * k;
    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3 * k
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(splitX - arrowSize, circleY - arrowSize / 2),
      Offset(splitX - arrowSize / 2, circleY),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(splitX - arrowSize / 2, circleY),
      Offset(splitX - arrowSize, circleY + arrowSize / 2),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(splitX + arrowSize, circleY - arrowSize / 2),
      Offset(splitX + arrowSize / 2, circleY),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(splitX + arrowSize / 2, circleY),
      Offset(splitX + arrowSize, circleY + arrowSize / 2),
      arrowPaint,
    );

    final bool afterDominant = splitX > size.width / 2;
    final caption = afterDominant ? afterLabel : beforeLabel;

    final capTp = TextPainter(
      text: TextSpan(text: caption, style: tpl.labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final padX = 16 * k;
    final padY = 10 * k;
    final boxW = capTp.width + padX * 2;
    final boxH = tpl.labelStyle.fontSize! + padY * 2;
    final boxX = (size.width - boxW) / 2;
    final boxY = 60 * k;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(boxX, boxY, boxW, boxH), Radius.circular(12 * k)),
      Paint()..color = tpl.labelBg,
    );
    capTp.paint(canvas, Offset(boxX + padX, boxY + padY));

    if (master != null) {
      _drawMasterBadge(canvas, size, k, 0, master, masterLogoImage);
    }
  }

  // === REVEAL / ВСПЫШКА ===
  static void _paintReveal(
    Canvas canvas,
    Size size,
    double v, {
    required List<ui.Image> images,
    required List<String> labels,
    required TemplateConfig tpl,
    Master? master,
    ui.Image? masterLogoImage,
  }) {
    final n = images.length;
    final idx = v.floor() % n;
    final t = (v - v.floor()).clamp(0.0, 1.0);
    final k = size.width / tpl.width;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.black);

    final inner = Rect.fromLTWH(0, 0, size.width, size.height);

    double flashIntensity = 0.0;
    if (t < 0.3) {
      final flashPhase = t / 0.3;
      flashIntensity = flashPhase < 0.5 ? flashPhase * 2 : 2 - flashPhase * 2;
    }

    double photoOpacity = 0.0;
    if (t >= 0.15 && t < 0.3) {
      photoOpacity = (t - 0.15) / 0.15;
    } else if (t >= 0.3 && t < 0.75) {
      photoOpacity = 1.0;
    } else if (t >= 0.75 && t < 0.9) {
      photoOpacity = (0.9 - t) / 0.15;
    }

    final double photoScale = 1.0 + 0.08 * t;

    if (photoOpacity > 0) {
      _drawContain(canvas, images[idx], inner, photoOpacity,
          scale: photoScale);
    }

    if (flashIntensity > 0) {
      canvas.drawRect(
          inner, Paint()..color = Colors.white.withOpacity(flashIntensity));
    }

    final captionOpacity = ((photoOpacity - 0.3) / 0.7).clamp(0.0, 1.0);
    if (captionOpacity > 0) {
      final tp = TextPainter(
        text: TextSpan(text: labels[idx], style: tpl.labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final ls = tpl.labelStyle.fontSize! * k;
      final padX = 20 * k;
      final padY = 14 * k;
      final boxW = tp.width + padX * 2;
      final boxH = ls + padY * 2;
      final lx = (size.width - boxW) / 2;
      final ly = 80 * k;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(lx, ly, boxW, boxH), Radius.circular(14 * k)),
        Paint()..color = tpl.labelBg.withOpacity(captionOpacity),
      );
      tp.paint(canvas, Offset(lx + padX, ly + padY));
    }

    if (master != null) {
      _drawMasterBadge(canvas, size, k, 0, master, masterLogoImage);
    }
  }

  // === MAGAZINE ===
  static void _paintMagazine(
    Canvas canvas,
    Size size,
    double v, {
    required List<ui.Image> images,
    required List<String> labels,
    required TemplateConfig tpl,
    Master? master,
    ui.Image? masterLogoImage,
  }) {
    final n = images.length;
    final idx = v.floor().clamp(0, n - 1);
    final t = (v - v.floor()).clamp(0.0, 1.0);
    final k = size.width / tpl.width;
    final bool hasNext = idx < n - 1;

    const black = Color(0xFF111111);
    const paper = Color(0xFFFAF7F2);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = paper);

    final masthead = TextPainter(
      text: TextSpan(
        text: 'НОГОТОЧКИ',
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: 110 * k,
          fontWeight: FontWeight.w900,
          color: black,
          letterSpacing: 14 * k,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    masthead.paint(canvas, Offset((size.width - masthead.width) / 2, 70 * k));

    final now = DateTime.now();
    const months = [
      'ЯНВАРЬ', 'ФЕВРАЛЬ', 'МАРТ', 'АПРЕЛЬ', 'МАЙ', 'ИЮНЬ',
      'ИЮЛЬ', 'АВГУСТ', 'СЕНТЯБРЬ', 'ОКТЯБРЬ', 'НОЯБРЬ', 'ДЕКАБРЬ'
    ];
    final issue = TextPainter(
      text: TextSpan(
        text: '№ ${now.month} • ${months[now.month - 1]} ${now.year} • ТРЕНД 2026',
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: 26 * k,
          color: const Color(0xFF777777),
          letterSpacing: 4 * k,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    issue.paint(canvas, Offset((size.width - issue.width) / 2, 215 * k));

    final photoArea = Rect.fromLTRB(
        50 * k, 300 * k, size.width - 50 * k, size.height - 330 * k);
    final kenBurns = 1.0 + 0.05 * t;
    _drawCover(canvas, images[idx], photoArea, 1.0, scale: kenBurns);

    canvas.drawRect(photoArea, Paint()
      ..color = black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * k);

    final headline = TextPainter(
      text: TextSpan(
        text: labels[idx],
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: 120 * k,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 16 * k),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    headline.paint(canvas,
        Offset((size.width - headline.width) / 2,
            photoArea.bottom - headline.height - 40 * k));

    final masterLine = master != null
        ? 'МАСТЕР • ${master.name.toUpperCase()}'
        : 'ДО/ПОСЛЕ • ЭКСКЛЮЗИВ';
    final bottom = TextPainter(
      text: TextSpan(
        text: masterLine,
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: 40 * k,
          fontWeight: FontWeight.w700,
          color: black,
          letterSpacing: 3 * k,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    bottom.paint(
        canvas, Offset((size.width - bottom.width) / 2, size.height - 260 * k));

    final sub = TextPainter(
      text: TextSpan(
        text: 'Эксклюзивное преображение: как нарисовали — так и получилось',
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: 26 * k,
          fontStyle: FontStyle.italic,
          color: const Color(0xFF777777),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    sub.paint(
        canvas, Offset((size.width - sub.width) / 2, size.height - 200 * k));

    final bcX = size.width - 220 * k;
    final bcY = size.height - 140 * k;
    final rand = math.Random(42);
    double x = bcX;
    for (int i = 0; i < 20; i++) {
      final w = (2 + rand.nextInt(6)) * k;
      canvas.drawRect(Rect.fromLTWH(x, bcY, w, 80 * k), Paint()..color = black);
      x += w + 4 * k;
    }

    double whiteOverlay = 0.0;
    if (t < 0.12) {
      whiteOverlay = 1 - t / 0.12;
    } else if (hasNext && t > 0.88) {
      whiteOverlay = (t - 0.88) / 0.12;
    }
    if (whiteOverlay > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..color = paper.withOpacity(whiteOverlay));
    }
  }

  /// Cover-кроп: фото заполняет область целиком
  static void _drawCover(Canvas canvas, ui.Image image, Rect area,
      double opacity,
      {double scale = 1.0}) {
    final s =
        math.max(area.width / image.width, area.height / image.height) * scale;
    final w = image.width * s;
    final h = image.height * s;
    final sx = (w - area.width) / 2 / s;
    final sy = (h - area.height) / 2 / s;
    final sw = area.width / s;
    final sh = area.height / s;
    canvas.save();
    canvas.clipRect(area);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(sx, sy, sw, sh),
      area,
      Paint()..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0, 1)),
    );
    canvas.restore();
  }

  static double _easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  /// Бейдж мастера: розовая рамка + розовые буквы на полупрозрачном белом.
  /// [baseOffsetY] — смещение от низа кадра (для cinematic с letterbox)
  static void _drawMasterBadge(
    Canvas canvas,
    Size size,
    double k,
    double baseOffsetY,
    Master master,
    ui.Image? masterLogoImage,
  ) {
    const pink = Color(0xFFE91E63);
    final double s = size.width / 480;

    final nameTp = TextPainter(
      text: TextSpan(
        text: master.name,
        style: TextStyle(
          color: pink,
          fontSize: 18 * s,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final avatarR = 16 * s;
    final gap = 8 * s;
    final padX = 12 * s;
    final padY = 8 * s;
    final blockW = padX * 2 + avatarR * 2 + gap + nameTp.width;
    final blockH = padY * 2 + math.max(avatarR * 2, nameTp.height);
    final bx = (size.width - blockW) / 2;
    final by = size.height - baseOffsetY - blockH - 28 * s;

    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, blockW, blockH), Radius.circular(16 * s));

    canvas.drawRRect(rrect, Paint()..color = Colors.white.withOpacity(0.85));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = pink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * s,
    );

    final avatarCenter = Offset(bx + padX + avatarR, by + blockH / 2);

    if (master.isCustomIcon && masterLogoImage != null) {
      canvas.save();
      canvas.clipPath(Path()
        ..addOval(Rect.fromCircle(center: avatarCenter, radius: avatarR)));
      final srcW = masterLogoImage.width.toDouble();
      final srcH = masterLogoImage.height.toDouble();
      final dst = Rect.fromCircle(center: avatarCenter, radius: avatarR);
      final sc = math.max(dst.width / srcW, dst.height / srcH);
      final sw = dst.width / sc;
      final sh = dst.height / sc;
      final sx = (srcW - sw) / 2;
      final sy = (srcH - sh) / 2;
      canvas.drawImageRect(
          masterLogoImage, Rect.fromLTWH(sx, sy, sw, sh), dst, Paint());
      canvas.restore();
    } else {
      canvas.drawCircle(avatarCenter, avatarR, Paint()..color = pink);
      final icon = MasterIcons.getIconByName(master.iconName ?? 'auto_awesome');
      final iconTp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            fontSize: 18 * s,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconTp.paint(canvas,
          avatarCenter - Offset(iconTp.width / 2, iconTp.height / 2));
    }

    nameTp.paint(canvas,
        Offset(bx + padX + avatarR * 2 + gap, by + blockH / 2 - nameTp.height / 2));
  }

  static void _drawSparkles(
      Canvas canvas, Rect area, double transT, double k, List<Offset> seeds) {
    final center = area.center;
    final diag = math.sqrt(area.width * area.width + area.height * area.height);
    for (int i = 0; i < seeds.length; i++) {
      final s = seeds[i];
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
          Paint()
            ..color = Colors.white.withOpacity(alpha * 0.5)
            ..strokeWidth = 1 * k);
      canvas.drawLine(Offset(pos.dx, pos.dy - r * 2),
          Offset(pos.dx, pos.dy + r * 2),
          Paint()
            ..color = Colors.white.withOpacity(alpha * 0.5)
            ..strokeWidth = 1 * k);
    }
  }

  static void _drawCornerSparkles(Canvas canvas, Size size, double v, double k) {
    for (int i = 0; i < 4; i++) {
      final tw = 0.5 + 0.5 * math.sin(v * 2 * math.pi + i * 1.7);
      final tp = TextPainter(
        text: TextSpan(
            text: '✨', style: TextStyle(fontSize: (20 + 8 * tw) * k)),
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

  static void _drawContain(Canvas canvas, ui.Image image, Rect area,
      double opacity,
      {double dx = 0, double scale = 1.0}) {
    final s =
        math.min(area.width / image.width, area.height / image.height) * scale;
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
}