import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../models/nail_session.dart';

/// Сервис работы с локальной базой данных.
/// Использует Hive для хранения данных и файловую систему для фото.
class DatabaseService {
  static const String _clientsBox = 'clients';
  static const String _sessionsBox = 'sessions';

  static late Box _clients;
  static late Box _sessions;

  /// Инициализация БД (вызывается в main.dart)
  static Future<void> init() async {
    await Hive.initFlutter();
    _clients = await Hive.openBox(_clientsBox);
    _sessions = await Hive.openBox(_sessionsBox);
  }

  // ============ КЛИЕНТЫ ============

  /// Добавить клиента
  static Future<Client> addClient({required String name, String? phone}) async {
    final client = Client(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
      createdAt: DateTime.now(),
    );
    await _clients.put(client.id, client.toMap());
    return client;
  }

  /// Получить всех клиентов (отсортированных по дате)
  static List<Client> getClients() {
    final list = <Client>[];
    for (final key in _clients.keys) {
      final map = _clients.get(key);
      if (map != null) {
        list.add(Client.fromMap(Map<String, dynamic>.from(map)));
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Получить клиента по id
  static Client? getClient(String id) {
    final map = _clients.get(id);
    if (map == null) return null;
    return Client.fromMap(Map<String, dynamic>.from(map));
  }

  /// Удалить клиента
  static Future<void> deleteClient(String id) async {
    await _clients.delete(id);
    // Удаляем все сессии клиента
    final sessions = getSessionsByClient(id);
    for (final session in sessions) {
      await deleteSession(session.id);
    }
  }

  // ============ СЕССИИ ============

  /// Добавить сессию
  static Future<NailSession> addSession({
    required String clientId,
    String? note,
  }) async {
    final session = NailSession(
      id: const Uuid().v4(),
      clientId: clientId,
      note: note,
      createdAt: DateTime.now(),
    );
    await _sessions.put(session.id, session.toMap());
    return session;
  }

  /// Получить сессии клиента
  static List<NailSession> getSessionsByClient(String clientId) {
    final list = <NailSession>[];
    for (final key in _sessions.keys) {
      final map = _sessions.get(key);
      if (map != null) {
        final session = NailSession.fromMap(Map<String, dynamic>.from(map));
        if (session.clientId == clientId) {
          list.add(session);
        }
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Обновить сессию (добавить фото)
  static Future<void> updateSession(NailSession session) async {
    await _sessions.put(session.id, session.toMap());
  }

  /// Удалить сессию
  static Future<void> deleteSession(String id) async {
    final map = _sessions.get(id);
    if (map != null) {
      final session = NailSession.fromMap(Map<String, dynamic>.from(map));
      // Удаляем файлы фото
      if (session.beforePhotoPath != null) {
        final file = File(session.beforePhotoPath!);
        if (await file.exists()) await file.delete();
      }
      if (session.afterPhotoPath != null) {
        final file = File(session.afterPhotoPath!);
        if (await file.exists()) await file.delete();
      }
    }
    await _sessions.delete(id);
  }

  // ============ ФОТО ============

  /// Сохранить фото в постоянное хранилище приложения.
  /// Возвращает путь к сохраненному файлу.
  static Future<String> savePhoto(File sourceFile, String prefix) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/photos');

    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await sourceFile.copy('${photosDir.path}/$fileName');
    return savedFile.path;
  }
}