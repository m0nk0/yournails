import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/client.dart';
import '../models/nail_session.dart';
import '../services/database_service.dart';
import 'photo_view_screen.dart';
import '../widgets/home_app_bar.dart';

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

  /// Добавить новый визит с фото "до"
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
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Добавить фото "после"
  Future<void> _addAfterPhoto(NailSession session) async {
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
          'after_${session.id}',
        );

        final updatedSession = NailSession(
          id: session.id,
          clientId: session.clientId,
          beforePhotoPath: session.beforePhotoPath,
          tryOnPhotoPath: session.tryOnPhotoPath,
          afterPhotoPath: savedPath,
          note: session.note,
          createdAt: session.createdAt,
        );
        await DatabaseService.updateSession(updatedSession);

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
          // Информация о клиенте
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

          // Список визитов
          Expanded(
            child: _sessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[400]),
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

  /// Карточка визита с 3 фото: До / Примерка / После
  Widget _buildSessionCard(NailSession session) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Визит',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
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

            // 3 фото: До / Примерка / После
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildPhotoColumn(
                    'До',
                    session.hasBefore,
                    session.beforePhotoPath,
                    session,
                    null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPhotoColumn(
                    'Примерка',
                    session.hasTryOn,
                    session.tryOnPhotoPath,
                    session,
                    null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPhotoColumn(
                    'После',
                    session.hasAfter,
                    session.afterPhotoPath,
                    session,
                    () => _addAfterPhoto(session),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Колонка с фото
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
                              Icon(Icons.add_a_photo, color: Colors.pink, size: 32),
                              SizedBox(height: 4),
                              Text(
                                'Добавить',
                                style: TextStyle(
                                  color: Colors.pink,
                                  fontSize: 14,
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