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
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/top_message.dart';
import '../widgets/quick_menu.dart';
import '../widgets/nail_3d_renderer.dart';
import '../painters/nail_path.dart';
import '../painters/realistic_nail_painter.dart';
import 'client_detail_screen.dart';
import 'animation_screen.dart';

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

      // PNG-узор: декодируем и передаём ВНУТРЬ painter — он ляжет
      // под блики и глянец (правильный z-порядок, как принт под топом)
      ui.Image? patternImage;
      if (design.hasPattern && design.patternPath != null) {
        final pBytes = await File(design.patternPath!).readAsBytes();
        final pCompleter = Completer<ui.Image>();
        ui.decodeImageFromList(pBytes, (i) => pCompleter.complete(i));
        patternImage = await pCompleter.future;
      }

      // Ноготь со всеми 3D-слоями: купол, арка, свечение, блик, глянец,
      // бороздка кутикулы — ровно тот же painter, что и в превью
      RealisticNailPainter(
        design: design,
        width: zone.width,
        height: zone.height,
        patternImage: patternImage,
      ).paint(canvas, nailSize);

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
      if (mounted) {
        TopMessage.show(context, 'Сохранено в галерею ✓',
            color: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        TopMessage.show(context, 'Ошибка: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        title: const Text('В коллекцию'),
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
        cuticleColor: design.cuticleColor?.value, // цвет кожи клиента
        createdAt: DateTime.now(),
      ));
      if (mounted) {
        TopMessage.show(context, 'Дизайн в коллекции ✓', color: Colors.green);
      }
    }
  }

  /// Сохранить примерку в существующий визит (без создания нового).
  /// Вызывается, когда пришли из карточки клиента (targetSession != null).
  /// После сохранения — возврат в карточку: мастер видит свежее фото сразу.
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
        TopMessage.show(context, 'Примерка сохранена в визит ✓',
            color: Colors.green);
        // Возврат в карточку клиента — там продолжение потока (видео)
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        TopMessage.show(context, 'Ошибка при сохранении: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  Future<Client?> _selectOrCreateClient() async {
    final clients = DatabaseService.getClients();

    final selected = await showDialog<Client>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить клиенту'),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.person_add, color: AppColors.cyan, size: 28),
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
                        backgroundColor: AppColors.wine,
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
        title: const Text('Новый клиент'),
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

  /// Сохранение клиенту + АВТОПЕРЕХОД в карточку клиента:
  /// там мастер видит визит и получает авто-подсказку «сделать видео».
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
        TopMessage.show(context, 'Сохранено в карточку клиента ✓',
            color: Colors.green);
        // Логичное продолжение потока: карточка клиента,
        // где авто-подсказка предложит сделать видео
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClientDetailScreen(client: client),
          ),
        );
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        TopMessage.show(context, 'Ошибка при сохранении: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  /// Видео собирается из сохранённых визитов (минимум 2 фото).
  /// - Если пришли из карточки клиента (targetSession != null) →
  ///   идём в AnimationScreen сразу с этим визитом
  /// - Если визита ещё нет → предлагаем сохранить клиенту;
  ///   после сохранения откроется карточка, где уже будет кнопка Видео
  Future<void> _makeVideo() async {
    final session = widget.targetSession;

    if (session == null) {
      // Нет визита — просим сохранить клиенту, а потом видео сделаем
      // уже из карточки клиента (там авто-предложение после сохранения)
      final save = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Сделать видео'),
          content: const Text(
            'Видео собирается из сохранённых визитов.\n\n'
            'Сначала сохранить примерку клиенту — а потом из карточки '
            'сделать ролик «До → Примерка»?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Сохранить клиенту'),
            ),
          ],
        ),
      );
      if (save == true) {
        // _saveToClient откроет карточку клиента, где уже есть кнопка Видео
        await _saveToClient();
      }
      return;
    }

    // Визит есть — проверяем, что в нём минимум 2 фото
    final hasEnough = [session.hasBefore, session.hasTryOn, session.hasAfter]
            .where((b) => b)
            .length >=
        2;
    if (!hasEnough) {
      TopMessage.show(
        context,
        'Для видео нужно минимум 2 фото в визите',
        color: Colors.orange,
      );
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnimationScreen(session: session),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final render = design.getRender();
    final tablet = Responsive.isTablet(context);
    final compact = Responsive.isCompact(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат'),
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

          // Панель действий: navy-градиент, единый язык кнопок 2×2
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
                  decoration: const BoxDecoration(
                    gradient: AppGradients.darkPanel,
                  ),
                  padding: EdgeInsets.all(Responsive.pad(context)),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Сводка дизайна
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: render.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.onDarkSoft, width: 1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${design.color?.name ?? 'Цвет'} • ${design.density.toInt()} сл. • ${NailPattern.getTypeName(design.pattern.type)}',
                                style: TextStyle(
                                  color: AppColors.onDark,
                                  fontSize: Responsive.fs(context, 15),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: tablet ? 14 : 10),

                        // РЯД 1: сохранить клиенту (градиент, шире) + видео
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: compact ? 50 : 56,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.cta,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
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
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        : const Icon(Icons.person_pin, size: 22),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _isSaving
                                            ? 'Сохранение...'
                                            : (widget.targetSession != null
                                                ? 'Сохранить в визит'
                                                : 'Сохранить клиенту'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: tablet ? 10 : 8),
                            Expanded(
                              flex: 2,
                              child: _panelButton(
                                icon: Icons.movie_creation_outlined,
                                label: 'Видео',
                                onTap: _isSaving ? null : _makeVideo,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: tablet ? 10 : 8),

                        // РЯД 2: коллекция + галерея (по 2 кнопки в ряду,
                        // шрифт крупный — места теперь хватает)
                        Row(
                          children: [
                            Expanded(
                              child: _panelButton(
                                icon: Icons.bookmark_add_outlined,
                                label: 'В коллекцию',
                                onTap: _saveToCollection,
                              ),
                            ),
                            SizedBox(width: tablet ? 10 : 8),
                            Expanded(
                              child: _panelButton(
                                icon: Icons.download_outlined,
                                label: 'В галерею',
                                onTap: _isSaving ? null : _saveToGallery,
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
          ),
        ],
      ),
    );
  }

  /// Outline-кнопка второго ряда: светлый контур на navy, текст не режется
  Widget _panelButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final compact = Responsive.isCompact(context);
    return SizedBox(
      height: compact ? 50 : 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: compact ? 18 : 22),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onDark,
          side: const BorderSide(color: AppColors.onDarkSoft, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}