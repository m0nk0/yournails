import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../library/unified_library_service.dart';
import '../models/my_design.dart';
import '../services/database_service.dart';
import '../utils/top_message.dart';

/// Экспорт и импорт всей библиотеки мастера одним файлом `.yournails`.
///
/// Формат файла (JSON):
/// {
///   "format": "yournails",
///   "version": 1,
///   "exportedAt": ISO8601,
///   "colors": [ ... ],          // мои цвета (library.json секция)
///   "materials": [ ... ],       // мои материалы
///   "designs": [                // мои дизайны-рецепты и картинки
///     { ...toMap() MyDesign...,
///       "imageBase64": "..."    // ТОЛЬКО для картинок
///     }
///   ]
/// }
///
/// Сценарии использования:
/// - бэкап перед обновлением приложения / сменой телефона
/// - перенос базы между телефонами через шаринг (Telegram и т.п.)
/// - поделиться подборкой с коллегой
class LibraryToolsScreen extends StatefulWidget {
  const LibraryToolsScreen({super.key});

  @override
  State<LibraryToolsScreen> createState() => _LibraryToolsScreenState();
}

class _LibraryToolsScreenState extends State<LibraryToolsScreen> {
  bool _working = false;

  /// Собирает библиотеку в JSON и шарит через системный шерер.
  Future<void> _export() async {
    setState(() => _working = true);
    try {
      // 1) Собираем цвета и материалы из library.json
      final sections = await UnifiedLibraryService.exportSections();
      final colors = sections['colors'] as List;
      final materials = sections['materials'] as List;

      // 2) Собираем MyDesigns (рецепты + картинки)
      final myDesigns = DatabaseService.getMyDesigns();
      final List<Map<String, dynamic>> designsOut = [];
      for (final d in myDesigns) {
        final m = d.toMap();
        // Для картинок кладём содержимое файла в base64 — иначе
        // локальный imagePath не переживёт перенос на другой телефон.
        if (d.isImage && d.imagePath != null) {
          final f = File(d.imagePath!);
          if (await f.exists()) {
            final bytes = await f.readAsBytes();
            m['imageBase64'] = base64Encode(bytes);
          }
        }
        // imagePath НЕ экспортируем: на другом телефоне путь другой
        m.remove('imagePath');
        designsOut.add(m);
      }

      // 3) Итоговый манифест
      final manifest = {
        'format': 'yournails',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'colors': colors,
        'materials': materials,
        'designs': designsOut,
      };

      // 4) Сохраняем во временный файл и шарим
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final file = File('${dir.path}/yournails_$stamp.yournails');
      await file.writeAsString(jsonEncode(manifest));

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Бэкап библиотеки «Твои Ноготочки»: '
            '${colors.length} цветов, ${materials.length} материалов, '
            '${designsOut.length} дизайнов',
      );

      if (mounted) {
        TopMessage.show(context, 'Библиотека отправлена ✓',
            color: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        TopMessage.show(context, 'Ошибка экспорта: $e', color: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// Импорт: выбор файла → предпросмотр → подтверждение → слияние.
  Future<void> _import() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;

      final file = File(path);
      if (!await file.exists()) {
        _err('Файл не найден');
        return;
      }
      final raw = await file.readAsString();
      Map<String, dynamic> manifest;
      try {
        manifest = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        _err('Это не файл библиотеки «Твои Ноготочки»');
        return;
      }

      if (manifest['format'] != 'yournails') {
        _err('Неверный формат файла');
        return;
      }

      final colors = (manifest['colors'] as List?) ?? <dynamic>[];
      final materials = (manifest['materials'] as List?) ?? <dynamic>[];
      final designs = (manifest['designs'] as List?) ?? <dynamic>[];
      final exportedAt = manifest['exportedAt'] as String?;

      // 1) ПРЕДПРОСМОТР
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Импорт библиотеки',
              style: TextStyle(fontSize: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Бэкап от ${_prettyDate(exportedAt ?? '')}',
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 12),
              _statRow('🎨 Цвета', colors.length),
              _statRow('💎 Материалы', materials.length),
              _statRow('🖼 Дизайны', designs.length),
              const SizedBox(height: 12),
              const Text(
                'Дубликаты будут пропущены. Текущие данные не потеряются.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Импортировать'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      setState(() => _working = true);

      // 2) СЛИЯНИЕ цветов и материалов (через фасад, с инвалидацией кэша)
      final libResult = await UnifiedLibraryService.importSections(
        colors: colors,
        materials: materials,
      );
      final addedColors = libResult['colors'] ?? 0;
      final addedMaterials = libResult['materials'] ?? 0;

      // 3) СЛИЯНИЕ MyDesigns: для картинок — восстанавливаем файлы из base64
      int addedDesigns = 0;
      final existing = DatabaseService.getMyDesigns();
      final existingIds = existing.map((d) => d.id).toSet();

      final tempDir = await getTemporaryDirectory();
      for (final raw in designs) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final id = m['id'] as String?;
        if (id == null || existingIds.contains(id)) continue;

        final typeStr = m['type'] as String?;
        final isImage = typeStr == MyDesignType.image.name;

        // Для картинок — сохраняем base64 во временный файл,
        // затем через savePhoto (унифицированное хранилище)
        String? newPath;
        if (isImage && m['imageBase64'] is String) {
          try {
            final bytes = base64Decode(m['imageBase64'] as String);
            final tmp = File(
                '${tempDir.path}/import_${DateTime.now().millisecondsSinceEpoch}_$id.png');
            await tmp.writeAsBytes(bytes);
            newPath = await DatabaseService.savePhoto(tmp, 'pattern');
          } catch (_) {
            // Файл картинки не восстановили — пропускаем дизайн
            continue;
          }
        }

        // Собираем MyDesign с новым путём
        final design = MyDesign(
          id: id,
          name: (m['name'] as String?) ?? 'Импорт',
          type: isImage ? MyDesignType.image : MyDesignType.recipe,
          colorId: m['colorId'] as String?,
          materialId: m['materialId'] as String?,
          shapeName: (m['shapeName'] as String?) ?? 'oval',
          density: (m['density'] as num?)?.toDouble() ?? 2.0,
          brightness: (m['brightness'] as num?)?.toDouble() ?? 1.0,
          patternType: m['patternType'] as String?,
          patternColor: m['patternColor'] as int?,
          edgeDarken: (m['edgeDarken'] as num?)?.toDouble() ?? 0.3,
          highlightIntensity:
              (m['highlightIntensity'] as num?)?.toDouble() ?? 0.5,
          shadowIntensity: (m['shadowIntensity'] as num?)?.toDouble() ?? 0.4,
          cuticleColor: m['cuticleColor'] as int?,
          imagePath: newPath,
          createdAt: m['createdAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int)
              : DateTime.now(),
        );

        await DatabaseService.addMyDesign(design);
        existingIds.add(id);
        addedDesigns++;
      }

      if (mounted) {
        TopMessage.show(
          context,
          'Импортировано: $addedColors цветов, '
          '$addedMaterials материалов, $addedDesigns дизайнов',
          color: Colors.green,
        );
        setState(() => _working = false);
      }
    } catch (e) {
      if (mounted) setState(() => _working = false);
      _err('Ошибка импорта: $e');
    }
  }

  void _err(String msg) {
    if (mounted) TopMessage.show(context, msg, color: Colors.red);
  }

  String _prettyDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
        'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}, '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.isEmpty ? 'неизвестно' : iso;
    }
  }

  Widget _statRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text('$count',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Бэкап библиотеки', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Вся библиотека в одном файле',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Мои цвета, материалы и дизайны. Для бэкапа, '
                    'переноса на другой телефон или передачи коллеге.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  _bigButton(
                    icon: Icons.upload,
                    title: 'Экспортировать библиотеку',
                    subtitle: 'Получить файл .yournails и отправить куда нужно',
                    color: Colors.pink,
                    onTap: _working ? null : _export,
                  ),
                  const SizedBox(height: 14),

                  _bigButton(
                    icon: Icons.download,
                    title: 'Импортировать из файла',
                    subtitle: 'Выбрать .yournails и добавить в свою библиотеку',
                    color: Colors.deepPurple,
                    onTap: _working ? null : _import,
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.grey, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Данные хранятся только на устройстве. '
                            'Бэкап — единственная защита от потери.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_working)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bigButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 88,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 34, color: Colors.white),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 28, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}