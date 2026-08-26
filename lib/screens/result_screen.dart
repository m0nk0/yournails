import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../models/nail_zone.dart';
import '../models/selected_design.dart';
import '../models/nail_shape.dart';
import '../models/nail_pattern.dart';
import '../models/my_design.dart';
import '../services/database_service.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/nail_pattern_layer.dart';
import '../widgets/nail_3d_renderer.dart';

class ResultScreen extends StatefulWidget {
  final File imageFile;
  final NailZone zone;
  final SelectedDesign design;
  final Offset imageOffset;
  final double imageScale;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.zone,
    required this.design,
    required this.imageOffset,
    required this.imageScale,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;

  NailZone get zone => widget.zone;
  SelectedDesign get design => widget.design;

  /// Детерминированный рендер через Canvas (с 3D-эффектами)
  Future<Uint8List> _renderTryOnImage({bool withDesign = true}) async {
    final mq = MediaQuery.of(context);
    final double W = mq.size.width;
    final double H =
        mq.size.height - mq.padding.top - AppBar().preferredSize.height;
    const double ratio = 2.0;

    final bytes = await widget.imageFile.readAsBytes();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (i) => completer.complete(i));
    final photo = await completer.future;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(ratio);

    final s = math.min(W / photo.width, H / photo.height);
    final double w = photo.width * s * widget.imageScale;
    final double h = photo.height * s * widget.imageScale;
    final double cx = W / 2 + widget.imageOffset.dx;
    final double cy = H / 2 + widget.imageOffset.dy;
    final dst = Rect.fromLTWH(cx - w / 2, cy - h / 2, w, h);

    canvas.drawImageRect(
      photo,
      Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble()),
      dst,
      Paint(),
    );

    if (withDesign) {
      final render = design.getRender();
      final material = design.material;

      canvas.save();
      canvas.translate(zone.x, zone.y);
      canvas.rotate(zone.rotation * math.pi / 180);

      final rect = Rect.fromLTWH(
        -zone.width / 2,
        -zone.height / 2,
        zone.width,
        zone.height,
      );
      final rrect = NailShapeHelper.getBorderRadius(
              design.shape, zone.width, zone.height)
          .toRRect(rect);

      // Тень под ногтем
      if (design.shadowIntensity > 0) {
        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(design.shadowIntensity * 0.5)
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, 6 * design.shadowIntensity);
        canvas.save();
        canvas.translate(0, 4 * design.shadowIntensity);
        canvas.drawRRect(rrect, shadowPaint);
        canvas.restore();
      }

      canvas.clipRRect(rrect);

      // Слой 1: цвет
      canvas.drawRect(
        rect,
        Paint()..color = render.color.withOpacity(render.opacity),
      );

      // Слой 2: радиальный объём
      if (design.edgeDarken > 0) {
        final edgePaint = Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(design.edgeDarken * 0.4),
            ],
            stops: const [0.5, 1.0],
          ).createShader(rect);
        canvas.drawRect(rect, edgePaint);
      }

      // Слой 3: рисунок
      if (design.hasPatternDraw) {
        canvas.save();
        canvas.translate(rect.left, rect.top);
        NailPatternPainter(design.pattern)
            .paint(canvas, Size(zone.width, zone.height));
        canvas.restore();
      }

      // Слой 4: PNG-картинка
      if (design.hasPattern) {
        final pBytes = await File(design.patternPath!).readAsBytes();
        final pCompleter = Completer<ui.Image>();
        ui.decodeImageFromList(pBytes, (i) => pCompleter.complete(i));
        final pImg = await pCompleter.future;
        canvas.drawImageRect(
          pImg,
          Rect.fromLTWH(0, 0, pImg.width.toDouble(), pImg.height.toDouble()),
          rect,
          Paint(),
        );
      }

      // НОВОЕ Слой 5: C-изгиб (бока темнее)
      if (design.edgeDarken > 0) {
        final cPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.black.withOpacity(design.edgeDarken * 0.45),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(design.edgeDarken * 0.45),
            ],
            stops: const [0.0, 0.25, 0.75, 1.0],
          ).createShader(rect);
        canvas.drawRect(rect, cPaint);
      }

            // Слой 6: световая колонна — ШИРЕ и РАЗМЫТЕЕ
      if (design.highlightIntensity > 0) {
        final lPaint = Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(design.highlightIntensity * 0.45),
              Colors.transparent,
            ],
            stops: const [0.25, 0.5, 0.75],
          ).createShader(rect);
        canvas.drawRect(rect, lPaint);
      }

      // Слой 7: блик сверху-слева
      if (design.highlightIntensity > 0) {
        final hlPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(design.highlightIntensity * 0.4),
              Colors.white.withOpacity(design.highlightIntensity * 0.1),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.7],
          ).createShader(rect);
        canvas.drawRect(rect, hlPaint);
      }

      // Слой 8: глянец
      if (material?.hasGloss ?? false) {
        final gi = material?.glossIntensity ?? 0.5;
        final glossPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(gi * 0.30),
              Colors.white.withOpacity(gi * 0.10),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.7],
          ).createShader(rect);
        canvas.drawRect(rect, glossPaint);
      }

      canvas.restore();
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage((W * ratio).round(), (H * ratio).round());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _saveToCollection() async {
    final nameController = TextEditingController(
      text:
          '${design.color?.name ?? 'Дизайн'} • ${NailShapeHelper.getName(design.shape)}',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('В коллекцию', style: TextStyle(fontSize: 20)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Название дизайна',
            hintText: 'Бордовый глянец квадрат',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (ok == true && nameController.text.trim().isNotEmpty) {
      await DatabaseService.addMyDesign(MyDesign(
        id: const Uuid().v4(),
        name: nameController.text.trim(),
        type: MyDesignType.recipe,
        colorId: design.color?.id,
        materialId: design.material?.id,
        shapeName: design.shape.name,
        density: design.density,
        brightness: design.brightness,
        patternType: design.pattern.isNone ? null : design.pattern.type.name,
        patternColor: design.pattern.isNone ? null : design.pattern.color.value,
        edgeDarken: design.edgeDarken,
        highlightIntensity: design.highlightIntensity,
        shadowIntensity: design.shadowIntensity,
        createdAt: DateTime.now(),
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Дизайн сохранён в коллекцию'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<Client?> _selectOrCreateClient() async {
    final clients = DatabaseService.getClients();

    final selected = await showDialog<Client>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить клиенту', style: TextStyle(fontSize: 20)),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.person_add, color: Colors.pink, size: 28),
                  title: const Text('Новый клиент',
                      style: TextStyle(fontSize: 18)),
                  onTap: () => Navigator.pop(
                    context,
                    Client(id: 'NEW', name: '', createdAt: DateTime.now()),
                  ),
                ),
                const Divider(),
                ...clients.map((c) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.pink,
                        child: Text(
                          c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(c.name, style: const TextStyle(fontSize: 18)),
                      subtitle: c.phone != null ? Text(c.phone!) : null,
                      onTap: () => Navigator.pop(context, c),
                    )),
              ],
            ),
          ),
        ),
      ),
    );

    if (selected == null) return null;

    if (selected.id == 'NEW') {
      return _createNewClient();
    }
    return selected;
  }

  Future<Client?> _createNewClient() async {
    final nameController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый клиент', style: TextStyle(fontSize: 20)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Имя *',
            hintText: 'Анна',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (ok == true && nameController.text.trim().isNotEmpty) {
      return DatabaseService.addClient(name: nameController.text.trim());
    }
    return null;
  }

  Future<void> _saveToClient() async {
    setState(() => _isSaving = true);

    try {
      final client = await _selectOrCreateClient();
      if (client == null) {
        setState(() => _isSaving = false);
        return;
      }

      final tryOnBytes = await _renderTryOnImage(withDesign: true);
      final beforeBytes = await _renderTryOnImage(withDesign: false);

      final tempDir = await getTemporaryDirectory();

      final tryOnTemp = File('${tempDir.path}/tryon_temp.png');
      await tryOnTemp.writeAsBytes(tryOnBytes);
      final tryOnPath =
          await DatabaseService.savePhoto(tryOnTemp, 'tryon_${client.id}');
      await tryOnTemp.delete();

      final beforeTemp = File('${tempDir.path}/before_temp.png');
      await beforeTemp.writeAsBytes(beforeBytes);
      final beforePath =
          await DatabaseService.savePhoto(beforeTemp, 'before_${client.id}');
      await beforeTemp.delete();

      await DatabaseService.addSessionWithPhotos(
        clientId: client.id,
        beforePhotoPath: beforePath,
        tryOnPhotoPath: tryOnPath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Сохранено клиенту: ${client.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при сохранении: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final render = design.getRender();

    return Scaffold(
      appBar: const HomeAppBar(
        title: Text('Результат', style: TextStyle(fontSize: 22)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: widget.imageOffset,
              child: Transform.scale(
                scale: widget.imageScale,
                child: Image.file(
                  widget.imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          Positioned(
            left: zone.x - zone.width / 2,
            top: zone.y - zone.height / 2,
            child: Transform.rotate(
              angle: zone.rotation * math.pi / 180,
              child: Nail3DRenderer(
                design: design,
                width: zone.width,
                height: zone.height,
              ),
            ),
          ),

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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: render.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${design.color?.name ?? 'Цвет'} • ${design.density.toInt()} сл. • ${NailPattern.getTypeName(design.pattern.type)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: const Text('← Назад'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveToClient,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.person_pin),
                          label: Text(
                              _isSaving ? 'Сохранение...' : 'Сохранить клиенту'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _saveToCollection,
                      icon: const Icon(Icons.bookmark_add),
                      label: const Text('В коллекцию'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
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