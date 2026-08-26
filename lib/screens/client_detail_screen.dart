import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/client.dart';
import '../models/nail_session.dart';
import '../services/database_service.dart';
import '../widgets/home_app_bar.dart';
import 'photo_view_screen.dart';
import 'animation_screen.dart';
import 'align_after_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final Client client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final ImagePicker _picker = ImagePicker();
  List<NailSession> _sessions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    setState(() {
      _sessions = DatabaseService.getSessionsByClient(widget.client.id);
    });
  }

  Future<void> _addSessionWithBeforePhoto() async {
    final source = await _showSourceDialog();
    if (source == null) return;

    setState(() => _isLoading = true);

    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (photo != null) {
        final savedPath = await DatabaseService.savePhoto(
          File(photo.path),
          'before_${widget.client.id}',
        );

        await DatabaseService.addSessionWithPhotos(
          clientId: widget.client.id,
          beforePhotoPath: savedPath,
        );

        _loadSessions();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Фото "до" сохранено'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// НОВОЕ: добавление "ПОСЛЕ" ТОЛЬКО из галереи (для выравнивания по призраку)
  Future<void> _addAfterPhoto(NailSession session) async {
    // Сразу открываем галерею (камеру не используем, так как призрак показать нельзя)
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (photo == null) return; // Отмена выбора

    if (session.beforePhotoPath == null) {
      // Нет эталона "до" — сохраняем как есть (редкий случай)
      await _saveAfterDirect(session, File(photo.path));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Открываем экран выравнивания с призраком
      final aligned = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlignAfterScreen(
            beforeFile: File(session.beforePhotoPath!),
            afterFile: File(photo.path),
          ),
        ),
      );

      if (aligned is Uint8List) {
        final tempDir = await getTempDir();
        final tempFile = File('$tempDir/after_temp.png');
        await tempFile.writeAsBytes(aligned);
        final savedPath =
            await DatabaseService.savePhoto(tempFile, 'after_${session.id}');
        await tempFile.delete();
        await _updateAfter(session, savedPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> getTempDir() async {
    final d = await getApplicationDocumentsDirectory();
    return d.path;
  }

  Future<void> _saveAfterDirect(NailSession session, File file) async {
    setState(() => _isLoading = true);
    try {
      final savedPath = await DatabaseService.savePhoto(file, 'after_${session.id}');
      await _updateAfter(session, savedPath);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAfter(NailSession session, String savedPath) async {
    final updated = NailSession(
      id: session.id,
      clientId: session.clientId,
      beforePhotoPath: session.beforePhotoPath,
      tryOnPhotoPath: session.tryOnPhotoPath,
      afterPhotoPath: savedPath,
      note: session.note,
      createdAt: session.createdAt,
    );
    await DatabaseService.updateSession(updated);
    _loadSessions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Фото "после" сохранено'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выбрать фото', style: TextStyle(fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, size: 28),
              title: const Text('Сделать фото', style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, size: 28),
              title: const Text('Из галереи', style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSession(NailSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить визит?', style: TextStyle(fontSize: 20)),
        content: const Text(
          'Визит и все фото будут удалены.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.deleteSession(session.id);
      _loadSessions();
    }
  }

  void _openPhotoView(String photoPath, String title, NailSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewScreen(
          imageFile: File(photoPath),
          title: title,
          session: session,
        ),
      ),
    );
  }

  void _openAnimation(NailSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimationScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        title: Text(
          widget.client.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.pink[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.client.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.client.phone != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '📞 ${widget.client.phone}',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Визитов: ${_sessions.length}',
                  style: TextStyle(fontSize: 18, color: Colors.grey[800]),
                ),
              ],
            ),
          ),

          Expanded(
            child: _sessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 20),
                        Text(
                          'Пока нет визитов',
                          style: TextStyle(fontSize: 22, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нажмите + чтобы добавить фото "до"',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return _buildSessionCard(session);
                    },
                  ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _addSessionWithBeforePhoto,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildSessionCard(NailSession session) {
    final photoCount = [
      session.hasBefore,
      session.hasTryOn,
      session.hasAfter
    ].where((b) => b).length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Визит',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(session.createdAt),
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                  onPressed: () => _deleteSession(session),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildPhotoColumn(
                    'До', session.hasBefore, session.beforePhotoPath, session, null),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPhotoColumn(
                    'Примерка', session.hasTryOn, session.tryOnPhotoPath, session, null),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPhotoColumn(
                    'После', session.hasAfter, session.afterPhotoPath, session,
                    () => _addAfterPhoto(session)),
                ),
              ],
            ),

            if (photoCount >= 2) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE91E63), Color(0xFF7B1FA2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE91E63).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _openAnimation(session),
                    icon: const Icon(Icons.movie_filter, size: 28, color: Colors.white),
                    label: const Text(
                      'ВИДЕО ДО/ПОСЛЕ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoColumn(
    String label,
    bool hasPhoto,
    String? photoPath,
    NailSession session,
    VoidCallback? onEmptyTap,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasPhoto
                ? GestureDetector(
                    onTap: () => _openPhotoView(photoPath!, label, session),
                    child: Image.file(
                      File(photoPath!),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : onEmptyTap != null
                    ? GestureDetector(
                        onTap: onEmptyTap,
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.pink[50],
                            border: Border.all(color: Colors.pink, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library, color: Colors.pink, size: 32),
                              SizedBox(height: 8),
                              Text(
                                '📸 Сделайте фото камерой,\nзатем выберите здесь',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.pink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(Icons.remove, color: Colors.grey, size: 32),
                      ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}