import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
  Client _client = Client(id: '', name: '', createdAt: DateTime.now());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _loadSessions();
  }

  void _loadSessions() {
    setState(() {
      _sessions = DatabaseService.getSessionsByClient(widget.client.id);
      final fresh = DatabaseService.getClient(widget.client.id);
      if (fresh != null) _client = fresh;
    });
  }

    // ============ СВЯЗЬ С КЛИЕНТОМ ============

  /// Диалог выбора способа связи
  Future<void> _showContactDialog() async {
    final phone = _client.phone ?? '';
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final hasPhone = digits.isNotEmpty;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Связаться: ${_client.name}',
          style: const TextStyle(fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _contactTile(
              icon: Icons.call,
              color: Colors.green,
              label: 'Позвонить',
              enabled: hasPhone,
              onTap: () async {
                Navigator.pop(context);
                await launchUrl(Uri.parse('tel:$digits'));
              },
            ),
            _contactTile(
              icon: Icons.telegram,
              color: const Color(0xFF26A5E4),
              label: 'Telegram',
              enabled: hasPhone,
              onTap: () async {
                Navigator.pop(context);
                final text = Uri.encodeComponent(
                    '${_client.name}, здравствуйте! Пора обновить ноготочки 💅');
                await launchUrl(
                  Uri.parse('https://t.me/+7$digits?text=$text'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
                        _contactTile(
              icon: Icons.chat_bubble,
              color: const Color(0xFF7B3FF2),
              label: 'Max',
              enabled: true,
              onTap: () async {
                Navigator.pop(context);
                // Копируем текст в буфер
                await Clipboard.setData(ClipboardData(
                    text: '${_client.name}, здравствуйте! '
                        'Пора обновить ноготочки 💅'));
                // Открываем главную страницу Max
                // Если приложение установлено — Android сам перехватит ссылку
                await launchUrl(Uri.parse('https://max.ru'),
                    mode: LaunchMode.externalApplication);
                if (mounted) {
                  _snack('Текст скопирован — вставьте в чат Max', Colors.green);
                }
              },
            ),
                        _contactTile(
              icon: Icons.public,
              color: const Color(0xFF0077FF),
              label: 'ВКонтакте',
              enabled: true,
              onTap: () async {
                Navigator.pop(context);
                // Копируем текст в буфер
                await Clipboard.setData(ClipboardData(
                    text: '${_client.name}, здравствуйте! '
                        'Пора обновить ноготочки 💅'));
                // Веб-ссылка на сообщения — открывается сразу (как в 1-й версии)
                await launchUrl(Uri.parse('https://vk.com/im'),
                    mode: LaunchMode.externalApplication);
                if (mounted) {
                  _snack('Текст скопирован — вставьте в чат ВК', Colors.green);
                }
              },
            ),
            _contactTile(
              icon: Icons.sms,
              color: Colors.blue,
              label: 'SMS',
              enabled: hasPhone,
              onTap: () async {
                Navigator.pop(context);
                final text = Uri.encodeComponent(
                    '${_client.name}, здравствуйте! Пора обновить ноготочки 💅');
                await launchUrl(Uri.parse('sms:$digits?body=$text'));
              },
            ),
            _contactTile(
              icon: Icons.email,
              color: Colors.orange,
              label: 'E-mail',
              enabled: true,
              onTap: () async {
                Navigator.pop(context);
                final subject = Uri.encodeComponent('Напоминание');
                final body = Uri.encodeComponent(
                    '${_client.name}, здравствуйте! Пора обновить ноготочки 💅');
                await launchUrl(Uri.parse('mailto:?subject=$subject&body=$body'));
              },
            ),
            const Divider(height: 24),
            _contactTile(
              icon: Icons.share,
              color: Colors.pink,
              label: 'Скопировать текст',
              enabled: true,
              onTap: () async {
                Navigator.pop(context);
                await Share.share(
                  '${_client.name}, здравствуйте! Пора обновить ноготочки 💅 '
                  'Есть окошки на этой неделе?',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTile({
    required IconData icon,
    required Color color,
    required String label,
    required bool enabled,
    required Future<void> Function() onTap,
  }) {
    return ListTile(
      enabled: enabled,
      leading: CircleAvatar(
        backgroundColor: enabled ? color : Colors.grey[300],
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 18,
              color: enabled ? Colors.black87 : Colors.grey[400])),
      trailing: Icon(Icons.chevron_right,
          color: enabled ? Colors.grey[600] : Colors.grey[300]),
      onTap: enabled ? () => onTap() : null,
    );
  }

  // ============ ЗАМЕТКА О КЛИЕНТЕ ============

  Future<void> _editClientNote() async {
    final controller = TextEditingController(text: _client.note ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заметка о клиенте', style: TextStyle(fontSize: 20)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Аллергии, предпочтения, особенности...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final updated = _client.copyWith(
        note: controller.text.trim().isEmpty ? null : controller.text.trim(),
      );
      await DatabaseService.updateClient(updated);
      _loadSessions();
    }
  }
  // ============ РЕДАКТИРОВАНИЕ ПРОФИЛЯ КЛИЕНТА ============

  Future<void> _editClientProfile() async {
    final nameController = TextEditingController(text: _client.name);
    final phoneController = TextEditingController(text: _client.phone ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Данные клиента', style: TextStyle(fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Имя *'),
              style: const TextStyle(fontSize: 18),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                hintText: '+7 999 123-45-67',
              ),
              style: const TextStyle(fontSize: 18),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (ok == true && nameController.text.trim().isNotEmpty) {
      final updated = _client.copyWith(
        name: nameController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
      );
      await DatabaseService.updateClient(updated);
      _loadSessions();
      if (mounted) _snack('Данные клиента обновлены', Colors.green);
    }
  }
  // ============ НОВЫЙ ВИЗИТ (фото "до") ============

  Future<void> _addSessionWithBeforePhoto() async {
    final source = await _showSourceDialog();
    if (source == null) return;
    setState(() => _isLoading = true);
    try {
      final XFile? photo =
          await _picker.pickImage(source: source, imageQuality: 80);
      if (photo != null) {
        final savedPath = await DatabaseService.savePhoto(
            File(photo.path), 'before_${widget.client.id}');
        await DatabaseService.addSessionWithPhotos(
            clientId: widget.client.id, beforePhotoPath: savedPath);
        _loadSessions();
        if (mounted) {
          _snack('Фото "до" сохранено', Colors.green);
        }
      }
    } catch (e) {
      if (mounted) _snack('Ошибка: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============ ФОТО "ПОСЛЕ" — С ВЫБОРОМ ИСТОЧНИКА ============

  Future<void> _addAfterPhoto(NailSession session) async {
    final source = await _showSourceDialog();
    if (source == null) return;

    final XFile? photo =
        await _picker.pickImage(source: source, imageQuality: 80);
    if (photo == null) return;

    if (session.beforePhotoPath == null) {
      await _saveAfterDirect(session, File(photo.path));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final aligned = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AlignAfterScreen(
                  beforeFile: File(session.beforePhotoPath!),
                  afterFile: File(photo.path),
                )),
      );
      if (aligned is Uint8List) {
        final tempDir = await getApplicationDocumentsDirectory();
        final tempFile = File('${tempDir.path}/after_temp.png');
        await tempFile.writeAsBytes(aligned);
        final savedPath =
            await DatabaseService.savePhoto(tempFile, 'after_${session.id}');
        await tempFile.delete();
        await _updateAfter(session, savedPath);
      }
    } catch (e) {
      if (mounted) _snack('Ошибка: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAfterDirect(NailSession session, File file) async {
    setState(() => _isLoading = true);
    try {
      final savedPath =
          await DatabaseService.savePhoto(file, 'after_${session.id}');
      await _updateAfter(session, savedPath);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAfter(NailSession session, String savedPath) async {
    final updated = session.copyWith(afterPhotoPath: savedPath);
    await DatabaseService.updateSession(updated);
    _loadSessions();
    if (mounted) _snack('Фото "после" сохранено', Colors.green);
  }

  // ============ УДАЛЕНИЕ ФОТО ============
  Future<void> _deletePhoto(NailSession session, String photoType) async {
    String? before = session.beforePhotoPath;
    String? tryOn = session.tryOnPhotoPath;
    String? after = session.afterPhotoPath;

    if (photoType == 'before') before = null;
    if (photoType == 'tryon') tryOn = null;
    if (photoType == 'after') after = null;

    if (before == null && tryOn == null && after == null &&
        session.price == null && (session.note ?? '').isEmpty) {
      await DatabaseService.deleteSession(session.id);
    } else {
      final updated = session.copyWith(
        beforePhotoPath: before,
        tryOnPhotoPath: tryOn,
        afterPhotoPath: after,
      );
      await DatabaseService.updateSession(updated);
    }
    _loadSessions();
  }

  // ============ ЗАМЕНА ФОТО ============
  Future<void> _replacePhoto(NailSession session, String photoType) async {
    final source = await _showSourceDialog();
    if (source == null) return;

    final XFile? photo =
        await _picker.pickImage(source: source, imageQuality: 80);
    if (photo == null) return;

    if (photoType == 'before') {
      final savedPath = await DatabaseService.savePhoto(
          File(photo.path), 'before_${session.id}');
      final updated = session.copyWith(beforePhotoPath: savedPath);
      await DatabaseService.updateSession(updated);
    } else if (photoType == 'after') {
      if (session.beforePhotoPath != null) {
        final aligned = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AlignAfterScreen(
                    beforeFile: File(session.beforePhotoPath!),
                    afterFile: File(photo.path),
                  )),
        );
        if (aligned is Uint8List) {
          final tempDir = await getApplicationDocumentsDirectory();
          final tempFile = File('${tempDir.path}/after_temp.png');
          await tempFile.writeAsBytes(aligned);
          final savedPath =
              await DatabaseService.savePhoto(tempFile, 'after_${session.id}');
          await tempFile.delete();
          final updated = session.copyWith(afterPhotoPath: savedPath);
          await DatabaseService.updateSession(updated);
        }
      } else {
        final savedPath = await DatabaseService.savePhoto(
            File(photo.path), 'after_${session.id}');
        final updated = session.copyWith(afterPhotoPath: savedPath);
        await DatabaseService.updateSession(updated);
      }
    }
    _loadSessions();
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Источник фото', style: TextStyle(fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, size: 28),
              title:
                  const Text('Сделать фото', style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, size: 28),
              title:
                  const Text('Из галереи', style: TextStyle(fontSize: 18)),
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
        content: const Text('Визит и все фото будут удалены.',
            style: TextStyle(fontSize: 16)),
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

  // ============ CRM: РЕДАКТИРОВАНИЕ ЦЕНЫ И ЗАМЕТКИ ============

  Future<void> _editPrice(NailSession session) async {
    final controller = TextEditingController(
        text: session.price != null ? session.price!.toInt().toString() : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сумма визита', style: TextStyle(fontSize: 20)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Сумма в ₽',
            hintText: '2500',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final value = double.tryParse(controller.text.trim());
      final updated = session.copyWith(price: value);
      await DatabaseService.updateSession(updated);
      _loadSessions();
    }
  }

  Future<void> _editSessionNote(NailSession session) async {
    final controller = TextEditingController(text: session.note ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заметка о визите', style: TextStyle(fontSize: 20)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Френч, укрепление базой...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final updated = session.copyWith(
        note: controller.text.trim().isEmpty ? null : controller.text.trim(),
      );
      await DatabaseService.updateSession(updated);
      _loadSessions();
    }
  }

  // ============ ПОДЕЛИТЬСЯ ВИЗИТОМ ============

  Future<void> _shareSession(NailSession session) async {
    final files = <XFile>[];
    if (session.hasBefore) files.add(XFile(session.beforePhotoPath!));
    if (session.hasTryOn) files.add(XFile(session.tryOnPhotoPath!));
    if (session.hasAfter) files.add(XFile(session.afterPhotoPath!));

    final text = StringBuffer()
      ..writeln('${_client.name} • ${session.service}')
      ..writeln('📅 ${_formatDate(session.createdAt)}')
      ..writeln(
          '💰 ${session.price != null ? '${session.price!.toInt()} ₽' : '—'}')
      ..writeln();
    if (session.note != null && session.note!.isNotEmpty) {
      text.writeln('📝 ${session.note}');
    }

    try {
      await Share.shareXFiles(
        files,
        text: text.toString(),
        subject: 'Визит ${_client.name}',
      );
    } catch (e) {
      if (mounted) _snack('Ошибка: $e', Colors.red);
    }
  }

  Future<void> _openPhotoView(String photoPath, String title,
      NailSession session, String photoType) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewScreen(
          imageFile: File(photoPath),
          title: title,
          session: session,
          photoType: photoType,
          onDelete: () => _deletePhoto(session, photoType),
          onReplace: photoType == 'tryon'
              ? null
              : () => _replacePhoto(session, photoType),
        ),
      ),
    );
    if (result == true) {
      _loadSessions();
    }
  }

  void _openAnimation(NailSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnimationScreen(session: session)),
    );
  }

  void _snack(String text, Color bg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: bg,
      ));
    }
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    final totalSum = _sessions.fold(0.0, (s, x) => s + (x.price ?? 0));

    return Scaffold(
      appBar: HomeAppBar(
        title: Text(_client.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 32),
            tooltip: 'Связаться',
            onPressed: _showContactDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // ============ ШАПКА КЛИЕНТА ============
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.pink[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_client.name,
                          style: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold)),
                    ),
                                        IconButton(
                      icon: const Icon(Icons.edit, size: 28),
                      tooltip: 'Изменить имя и телефон',
                      onPressed: _editClientProfile,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note, size: 32),
                      tooltip: 'Заметка о клиенте',
                      onPressed: _editClientNote,
                    ),
                  ],
                ),
                if (_client.phone != null) ...[
                  const SizedBox(height: 4),
                  Text('📞 ${_client.phone}',
                      style:
                          TextStyle(fontSize: 20, color: Colors.grey[700])),
                ],
                if (_client.note != null && _client.note!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.pink[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.orange, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_client.note!,
                              style: const TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    _miniStat('Визитов', '${_sessions.length}'),
                    const SizedBox(width: 20),
                    _miniStat('Всего', '${totalSum.toInt()} ₽'),
                    const SizedBox(width: 20),
                    _miniStat(
                        'Среднее',
                        _sessions.isEmpty
                            ? '0 ₽'
                            : '${(totalSum / _sessions.length).toInt()} ₽'),
                  ],
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
                        Text('Пока нет визитов',
                            style: TextStyle(
                                fontSize: 22, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text('Нажмите + чтобы добавить фото "до"',
                            style:
                                TextStyle(fontSize: 16, color: Colors.grey)),
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

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        Text(value,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ],
    );
  }

  Widget _buildSessionCard(NailSession session) {
    final photoCount = [session.hasBefore, session.hasTryOn, session.hasAfter]
        .where((b) => b)
        .length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === СТРОКА 1: дата + цена + действия ===
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Визит',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(_formatDate(session.createdAt),
                          style: TextStyle(
                              fontSize: 19, color: Colors.grey[600])),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _editPrice(session),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attach_money,
                            color: Colors.green, size: 26),
                        Text(
                          session.price != null
                              ? '${session.price!.toInt()} ₽'
                              : 'Сумма?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.share, color: Colors.pink, size: 32),
                  tooltip: 'Поделиться визитом',
                  onPressed: photoCount >= 1
                      ? () => _shareSession(session)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 32),
                  onPressed: () => _deleteSession(session),
                ),
              ],
            ),

            // === СТРОКА 2: услуга + заметка ===
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(session.service,
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.pink,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _editSessionNote(session),
                    child: Text(
                      session.note ?? 'Заметка о визите (тап — добавить)',
                      style: TextStyle(
                        fontSize: 18,
                        color: session.note != null
                            ? Colors.black87
                            : Colors.grey[500],
                        fontStyle:
                            session.note == null ? FontStyle.italic : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // === ФОТО: ДО / ПРИМЕРКА / ПОСЛЕ ===
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildPhotoColumn('До', session.hasBefore,
                      session.beforePhotoPath, session, 'before', null),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPhotoColumn('Примерка', session.hasTryOn,
                      session.tryOnPhotoPath, session, 'tryon', null),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPhotoColumn('После', session.hasAfter,
                      session.afterPhotoPath, session, 'after',
                      () => _addAfterPhoto(session)),
                ),
              ],
            ),

            if (photoCount >= 2) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFFE91E63),
                      Color(0xFF7B1FA2)
                    ]),
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
                    icon: const Icon(Icons.movie_filter,
                        size: 32, color: Colors.white),
                    label: const Text('ВИДЕО ДО/ПОСЛЕ',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
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

  Widget _buildPhotoColumn(String label, bool hasPhoto, String? photoPath,
      NailSession session, String photoType, VoidCallback? onEmptyTap) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasPhoto
                ? GestureDetector(
                    onTap: () =>
                        _openPhotoView(photoPath!, label, session, photoType),
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
                              Icon(Icons.photo_library,
                                  color: Colors.pink, size: 36),
                              SizedBox(height: 8),
                              Text(
                                '📸 Сделайте фото\nили выберите\nиз галереи',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.pink,
                                  fontSize: 12,
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
                        child: const Icon(Icons.remove,
                            color: Colors.grey, size: 36),
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