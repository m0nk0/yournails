import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../models/client.dart';
import '../models/nail_zone.dart';
import '../models/selected_design.dart';
import '../models/nail_shape.dart';
import '../services/database_service.dart';

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
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isSaving = false;

  NailZone get zone => widget.zone;
  SelectedDesign get design => widget.design;

  /// Выбор клиента или создание нового
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
                  leading: const Icon(Icons.person_add, color: Colors.pink, size: 28),
                  title: const Text('Новый клиент', style: TextStyle(fontSize: 18)),
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

  /// Создание нового клиента
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

  /// Сохранить примерку клиенту
  Future<void> _saveToClient() async {
    setState(() => _isSaving = true);

    try {
      // 1. Выбираем клиента
      final client = await _selectOrCreateClient();
      if (client == null) {
        setState(() => _isSaving = false);
        return;
      }

      // 2. Рендерим примерку в изображение
      final boundary = _repaintBoundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/tryon_temp.png');
      await tempFile.writeAsBytes(bytes);
      final tryOnPath = await DatabaseService.savePhoto(tempFile, 'tryon_${client.id}');
      await tempFile.delete();

      // 3. Сохраняем исходное фото как "до"
      final beforePath =
          await DatabaseService.savePhoto(widget.imageFile, 'before_${client.id}');

      // 4. Создаём сессию
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
    final material = design.material;
    final borderRadius = NailShapeHelper.getBorderRadius(design.shape, zone.width, zone.height);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      // ИСПРАВЛЕНО: Stack на весь экран, как в EditScreen
      body: Stack(
        children: [
          // Область рендеринга (фото + дизайн) на весь экран
          RepaintBoundary(
            key: _repaintBoundaryKey,
            child: Stack(
              children: [
                // Фото на весь экран (та же геометрия, что в EditScreen)
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

                // Наложение дизайна
                Positioned(
                  left: zone.x - zone.width / 2,
                  top: zone.y - zone.height / 2,
                  child: Transform.rotate(
                    angle: zone.rotation * math.pi / 180,
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      child: SizedBox(
                        width: zone.width,
                        height: zone.height,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Opacity(
                                opacity: render.opacity,
                                child: Container(color: render.color),
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
                                        Colors.white.withOpacity(
                                            (material?.glossIntensity ?? 0.5) * 0.30),
                                        Colors.white.withOpacity(
                                            (material?.glossIntensity ?? 0.5) * 0.10),
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
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Нижняя панель ПОВЕРХ фото (не влияет на геометрию)
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
                          '${design.color?.name ?? 'Цвет'} • ${design.density.toInt()} сл. • ${NailShapeHelper.getName(design.shape)}',
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
                          label: Text(_isSaving ? 'Сохранение...' : 'Сохранить клиенту'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
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