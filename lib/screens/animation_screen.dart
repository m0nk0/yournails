import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/master.dart';
import '../models/nail_session.dart';
import '../services/database_service.dart';
import '../widgets/video_renderer.dart';

class AnimationScreen extends StatefulWidget {
  final NailSession session;
  final List<String>? photoTypes; // null — все фото визита
  const AnimationScreen({super.key, required this.session, this.photoTypes});

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
  VideoTemplate _template = VideoTemplate.splitScreen;
  String _selectedGroup = '🔥 Тренды';

  List<Master> _masters = [];
  Master? _selectedMaster;
  ui.Image? _masterLogoImage;

  bool _isExporting = false;
  double _exportProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final files = <File>[];
    final labels = <String>[];
    final types = widget.photoTypes;

    if (widget.session.hasBefore &&
        (types == null || types.contains('before'))) {
      files.add(File(widget.session.beforePhotoPath!));
      labels.add('ДО');
    }
    if (widget.session.hasTryOn &&
        (types == null || types.contains('tryon'))) {
      files.add(File(widget.session.tryOnPhotoPath!));
      labels.add('ПРИМЕРКА');
    }
    if (widget.session.hasAfter &&
        (types == null || types.contains('after'))) {
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

    // Загружаем мастеров (автовыбор первого)
    final masters = DatabaseService.getMasters();
    final selected = masters.isNotEmpty ? masters.first : null;
    final logo = await _loadMasterLogo(selected);

    setState(() {
      _photoFiles = files;
      _images = images;
      _labels = labels;
      _masters = masters;
      _selectedMaster = selected;
      _masterLogoImage = logo;
    });

    if (_images.length >= 2) {
      _syncController();
    }
  }

    /// Синхронизирует контроллер превью с текущим шаблоном.
  /// Слайдер: upper = images.length - 1 (проход на каждую ПАРУ фото).
  /// Классика: upper = images.length (сегмент на каждое фото).
  void _syncController() {
    if (_images.length < 2) return;
    final double upper = VideoTemplates.get(_template).isSplitScreen
        ? (_images.length - 1).toDouble()
        : _images.length.toDouble();
    final int durationMs = (2500 * upper).round();

    // Пересоздаём контроллер (upperBound только для чтения)
    _controller?.dispose();
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: upper,
      duration: Duration(milliseconds: durationMs),
    )..repeat();

    if (mounted) setState(() {});
  }

  /// Загрузка логотипа мастера как ui.Image
  Future<ui.Image?> _loadMasterLogo(Master? m) async {
    if (m == null || !m.isCustomIcon || m.iconPath == null) return null;
    final file = File(m.iconPath!);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    final c = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (i) => c.complete(i));
    return c.future;
  }

  /// Смена мастера
  Future<void> _onMasterChanged(Master? m) async {
    final logo = await _loadMasterLogo(m);
    setState(() {
      _selectedMaster = m;
      _masterLogoImage = logo;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _exportMp4({bool toGallery = false}) async {
    if (_images.length < 2 || _isExporting) return;

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
    });

    try {
      final outputPath = await VideoRenderer.renderVideo(
        images: _images,
        labels: _labels,
        template: _template,
        transition: _transition,
        master: _selectedMaster,
        masterLogoImage: _masterLogoImage,
        segmentDurationSec: 2.5,
        fps: 30,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _exportProgress = progress);
          }
        },
      );

      if (outputPath == null) {
        throw Exception('Не удалось создать видео');
      }

      if (mounted) {
        if (toGallery) {
          await Gal.putVideo(outputPath);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Видео сохранено в галерею'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          await Share.shareXFiles(
            [XFile(outputPath)],
            text: 'Моя работа 💅 до и после',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Видео готово и отправлено'),
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
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportProgress = 0.0;
        });
      }
    }
  }

  /// Чип группы
  Widget _buildGroupChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.pink : Colors.white.withOpacity(0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Чип шаблона
  Widget _buildTemplateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.pink : Colors.white.withOpacity(0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

      List<VideoTemplate> _getTemplatesForGroup(String group) {
    if (group == '🔥 Тренды') {
      return [
        VideoTemplate.splitScreen,
        VideoTemplate.reveal,
        VideoTemplate.magazine,
      ];
    } else {
      return [
        VideoTemplate.clean,
        VideoTemplate.instagram,
        VideoTemplate.tiktok,
        VideoTemplate.glam,
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tpl = VideoTemplates.get(_template);
    final groupTemplates = _getTemplatesForGroup(_selectedGroup);

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
                                    v: _controller!.value,
                                    images: _images,
                                    labels: _labels,
                                    transition: _transition,
                                    tpl: tpl,
                                    master: _selectedMaster,
                                    masterLogoImage: _masterLogoImage,
                                  ),
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
                      // ===== ВЫБОР МАСТЕРА =====
                      if (_masters.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.person,
                                  color: Colors.pink, size: 20),
                              const SizedBox(width: 8),
                              const Text('Мастер: ',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                              Expanded(
                                child: _masters.length > 1
                                    ? DropdownButton<Master>(
                                        isExpanded: true,
                                        value: _selectedMaster,
                                        items: _masters
                                            .map((m) => DropdownMenuItem(
                                                  value: m,
                                                  child: Text(m.name,
                                                      style: const TextStyle(
                                                          fontSize: 14)),
                                                ))
                                            .toList(),
                                        onChanged: _onMasterChanged,
                                        dropdownColor: Colors.black87,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 14),
                                        underline: const SizedBox(),
                                      )
                                    : Text(
                                        _selectedMaster?.name ?? '',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 14),
                                      ),
                              ),
                            ],
                          ),
                        ),

                      // ===== ГРУППЫ ШАБЛОНОВ =====
                      SizedBox(
                        height: 44,
                        child: Row(
                          children: ['🔥 Тренды', '📼 Классика'].map((group) {
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                child: _buildGroupChip(
                                  label: group,
                                  isSelected: _selectedGroup == group,
                                  onTap: () {
                                    setState(() {
                                      _selectedGroup = group;
                                      final templates =
                                          _getTemplatesForGroup(group);
                                      _template = templates.first;
                                    });
                                    _syncController();
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                                          // ===== ШАБЛОНЫ В ВЫБРАННОЙ ГРУППЕ (в линию, по центру) =====
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width - 48,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: groupTemplates.map((t) {
                              final cfg = VideoTemplates.get(t);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _buildTemplateChip(
                                  label: '${cfg.icon} ${cfg.name}',
                                  isSelected: _template == t,
                                  onTap: () {
                                    setState(() => _template = t);
                                    _syncController();
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // ===== ПЕРЕХОДЫ (только для классики) =====
                      if (_selectedGroup == '📼 Классика') ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: TransitionType.values.map((tr) {
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _buildTemplateChip(
                                  label: names[tr]!,
                                  isSelected: _transition == tr,
                                  onTap: () => setState(() => _transition = tr),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      if (_isExporting) ...[
                        LinearProgressIndicator(
                          value: _exportProgress,
                          backgroundColor: Colors.white10,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.pink),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isExporting
                                  ? null
                                  : () => _exportMp4(toGallery: true),
                              icon: _isExporting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.download, size: 20),
                              label: const Text('Видео в галерею',
                                  style: TextStyle(fontSize: 14)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isExporting ? null : () => _exportMp4(),
                              icon: const Icon(Icons.share, size: 20),
                              label: const Text('Поделиться',
                                  style: TextStyle(fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
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
  final double v;
  final List<ui.Image> images;
  final List<String> labels;
  final TransitionType transition;
  final TemplateConfig tpl;
  final Master? master;
  final ui.Image? masterLogoImage;

  _FramePainter({
    required this.v,
    required this.images,
    required this.labels,
    required this.transition,
    required this.tpl,
    this.master,
    this.masterLogoImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    VideoRenderer.paintFrame(
      canvas,
      size,
      v,
      images: images,
      labels: labels,
      transition: transition,
      tpl: tpl,
      master: master,
      masterLogoImage: masterLogoImage,
    );
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) => true;
}