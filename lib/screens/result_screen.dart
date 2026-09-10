import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../models/nail_zone.dart';
import '../models/selected_design.dart';
import '../models/nail_shape.dart';
import '../models/nail_pattern.dart';
import '../models/my_design.dart';
import '../models/nail_session.dart';
import '../services/database_service.dart';
import '../utils/responsive.dart';
import '../utils/top_message.dart';
import '../widgets/quick_menu.dart';
import '../widgets/nail_3d_renderer.dart';
import '../painters/nail_path.dart';
import '../painters/realistic_nail_painter.dart';

class ResultScreen extends StatefulWidget {
  final File imageFile;
  final NailZone zone;
  final SelectedDesign design;
  final Offset imageOffset;
  final double imageScale;

  /// Визит для записи примерки (если пришли из карточки клиента).
  /// Если null — кнопка «Сохранить клиенту» создаёт новый визит.
  final NailSession? targetSession;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.zone,
    required this.design,
    required this.imageOffset,
    required this.imageScale,
    this.targetSession,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;

  NailZone get zone => widget.zone;
  SelectedDesign get design => widget.design;

  /// Детерминированный рендер через Canvas.
  /// Ноготь рисуется ТЕМ ЖЕ RealisticNailPainter, что и на экране, —
  /// сохранённая картинка совпадает с тем, что видит мастер (WYSIWYG).
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

    // Фото: contain + зум от центра + смещение
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
      canvas.save();
      canvas.translate(zone.x, zone.y);
      canvas.rotate(zone.rotation * math.pi / 180);
      canvas.translate(-zone.width / 2, -zone.height / 2);
      final nailSize = Size(zone.width, zone.height);

      // Контактная тень (как на экране)
      if (design.shadowIntensity > 0) {
        NailShadowPainter(
          shape: design.shape,
          intensity: design.shadowIntensity,
        ).paint(canvas, nailSize);
      }

      // Ноготь со всеми 3D-слоями: купол, арка, свечение, блик, глянец,
      // бороздка кутикулы — ровно тот же painter, что и в превью
      RealisticNailPainter(
        design: design,
        width: zone.width,
        height: zone.height,
      ).paint(canvas, nailSize);

      // PNG-узор поверх, обрезанный по форме ногтя
      if (design.hasPattern && design.patternPath != null) {
        final pBytes = await File(design.patternPath!).readAsBytes();
        final pCompleter = Completer<ui.Image>();
        ui.decodeImageFromList(pBytes, (i) => pCompleter.complete(i));
        final pImg = await pCompleter.future;
        canvas.save();
        canvas.clipPath(buildNailPath(zone.width, zone.height, design.shape));
        canvas.drawImageRect(
          pImg,
          Rect.fromLTWH(0, 0, pImg.width.toDouble(), pImg.height.toDouble()),
          Rect.fromLTWH(0, 0, zone.width, zone.height),
          Paint(),
        );
        canvas.restore();
      }

      canvas.restore();
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage((W * ratio).round(), (H * ratio).round());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  /// Сохранить примерку в галерею устройства
  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await _renderTryOnImage(withDesign: true);
      await Gal.putImageBytes(bytes);
    } catch (e) {
      if (mounted) {
        TopMessage.show(context, 'Ошибка: $e');
      }
    } finally {
      setState(() => _isSaving = false);
    }
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
        cuticleColor: design.cuticleColor?.value, // ← цвет кожи клиента
        createdAt: DateTime.now(),
      ));
    }
  }

  /// Сохранить примерку в существующий визит (без создания нового).
  /// Вызывается, когда пришли из карточки клиента (targetSession != null).
  Future<void> _saveToExistingSession() async {
    final session = widget.targetSession;
    if (session == null) return;
    setState(() => _isSaving = true);
    try {
      final tryOnBytes = await _renderTryOnImage(withDesign: true);
      final tempDir = await getTemporaryDirectory();
      final tryOnTemp = File('${tempDir.path}/tryon_temp.png');
      await tryOnTemp.writeAsBytes(tryOnBytes);
      final tryOnPath =
          await DatabaseService.savePhoto(tryOnTemp, 'tryon_${session.id}');
      await tryOnTemp.delete();

      final updated = NailSession(
        id: session.id,
        clientId: session.clientId,
        beforePhotoPath: session.beforePhotoPath,
        tryOnPhotoPath: tryOnPath,
        afterPhotoPath: session.afterPhotoPath,
        note: session.note,
        price: session.price,
        serviceName: session.serviceName,
        createdAt: session.createdAt,
      );
      await DatabaseService.updateSession(updated);
      if (mounted) {
        TopMessage.show(context, 'Примерка сохранена в визит',
            color: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        TopMessage.show(context, 'Ошибка при сохранении: $e');
      }
    } finally {
      setState(() => _isSaving = false);
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
    } catch (e) {
      if (mounted) {
        TopMessage.show(context, 'Ошибка при сохранении: $e');
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final render = design.getRender();
    final tablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        // Бургер-меню: Клиенты / Мои дизайны / На главный.
        // Отдельная кнопка «домой» убрана — она внутри меню.
        actions: const [QuickMenuButton()],
      ),
      body: Stack(
        children: [
          // Фото на весь экран
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

          // 3D-ноготь
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

          // Панель поверх (на планшете — центрирована)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: tablet ? 720 : double.infinity,
                ),
                child: Container(
                  color: Colors.black87,
                  padding: EdgeInsets.all(Responsive.pad(context)),
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Responsive.fs(context, 16),
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: tablet ? 16 : 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    vertical: tablet ? 16 : 14),
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                              ),
                              child: Text('← Назад',
                                  style: TextStyle(
                                      fontSize: Responsive.fs(context, 16))),
                            ),
                          ),
                          SizedBox(width: tablet ? 16 : 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : (widget.targetSession != null
                                      ? _saveToExistingSession
                                      : _saveToClient),
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.person_pin),
                              label: Text(
                                  _isSaving
                                      ? 'Сохранение...'
                                      : (widget.targetSession != null
                                          ? 'Сохранить в визит'
                                          : 'Сохранить клиенту'),
                                  style: TextStyle(
                                      fontSize: Responsive.fs(context, 15))),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    vertical: tablet ? 16 : 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: tablet ? 12 : 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saveToCollection,
                              icon: const Icon(Icons.bookmark_add),
                              label: Text('В коллекцию',
                                  style: TextStyle(
                                      fontSize: Responsive.fs(context, 14))),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    vertical: tablet ? 14 : 12),
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                              ),
                            ),
                          ),
                          SizedBox(width: tablet ? 12 : 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSaving ? null : _saveToGallery,
                              icon: const Icon(Icons.download),
                              label: Text('В галерею',
                                  style: TextStyle(
                                      fontSize: Responsive.fs(context, 14))),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    vertical: tablet ? 14 : 12),
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}