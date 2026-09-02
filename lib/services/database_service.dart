// lib/services/database_service.dart

import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../models/nail_session.dart';
import '../models/my_design.dart';
import '../models/master.dart';

/// Сервис работы с локальной базой данных.
/// Использует Hive для хранения данных и файловую систему для фото.
class DatabaseService {
  static const String _clientsBox = 'clients';
  static const String _sessionsBox = 'sessions';
  static const String _myDesignsBox = 'my_designs';
  static const String _mastersBox = 'masters';
  static const String _settingsBox = 'settings';

  static late Box _clients;
  static late Box _sessions;
  static late Box _myDesigns;
  static late Box _masters;
  static late Box _settings;

  /// Инициализация БД (вызывается в main.dart)
  static Future<void> init() async {
    await Hive.initFlutter();
    _clients = await Hive.openBox(_clientsBox);
    _sessions = await Hive.openBox(_sessionsBox);
    _myDesigns = await Hive.openBox(_myDesignsBox);
    _masters = await Hive.openBox(_mastersBox);
    _settings = await Hive.openBox(_settingsBox);
  }

  // ============ НАСТРОЙКИ ============

  /// Был ли онбординг пропущен (режим клиента)
  static bool get isOnboardingSkipped =>
      _settings.get('skip_onboarding', defaultValue: false) as bool;

  /// Установить флаг пропуска онбординга
  static Future<void> setOnboardingSkipped(bool value) async {
    await _settings.put('skip_onboarding', value);
  }

  // ============ НАСТРОЙКИ CRM ============

  /// Интервал напоминаний в днях (по умолчанию 28)
  static int get reminderDays =>
      _settings.get('reminder_days', defaultValue: 28) as int;

  static Future<void> setReminderDays(int days) async {
    await _settings.put('reminder_days', days);
  }

  /// Дефолтная цена визита в ₽ (по умолчанию 2000)
  static double get defaultPrice =>
      (_settings.get('default_price', defaultValue: 2000.0) as num).toDouble();

  static Future<void> setDefaultPrice(double price) async {
    await _settings.put('default_price', price);
  }

  // ============ МАСТЕРА ============

  /// Добавить мастера
  static Future<Master> addMaster({
    required String name,
    String? iconPath,
    String? iconName,
    bool isCustomIcon = false,
  }) async {
    final master = Master(
      id: const Uuid().v4(),
      name: name,
      iconPath: iconPath,
      iconName: iconName,
      isCustomIcon: isCustomIcon,
      createdAt: DateTime.now(),
    );
    await _masters.put(master.id, master.toMap());
    return master;
  }

  /// Получить всех мастеров (отсортированных по дате)
  static List<Master> getMasters() {
    final list = <Master>[];
    for (final key in _masters.keys) {
      final map = _masters.get(key);
      if (map != null) {
        list.add(Master.fromMap(Map<String, dynamic>.from(map)));
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Получить мастера по id
  static Master? getMaster(String id) {
    final map = _masters.get(id);
    if (map == null) return null;
    return Master.fromMap(Map<String, dynamic>.from(map));
  }

  /// Обновить мастера
  static Future<void> updateMaster(Master master) async {
    await _masters.put(master.id, master.toMap());
  }

  /// Удалить мастера
  static Future<void> deleteMaster(String id) async {
    final map = _masters.get(id);
    if (map != null) {
      final master = Master.fromMap(Map<String, dynamic>.from(map));
      // Если это своя картинка — удаляем файл
      if (master.isCustomIcon && master.iconPath != null) {
        final file = File(master.iconPath!);
        if (await file.exists()) await file.delete();
      }
    }
    await _masters.delete(id);
  }

  /// Получить активного мастера (первого в списке или null)
  static Master? getActiveMaster() {
    final masters = getMasters();
    return masters.isNotEmpty ? masters.first : null;
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

  /// Обновить клиента (заметки и т.д.)
  static Future<void> updateClient(Client client) async {
    await _clients.put(client.id, client.toMap());
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

  /// Создать сессию сразу с фото (+ CRM-данные: цена и услуга)
  static Future<NailSession> addSessionWithPhotos({
    required String clientId,
    String? beforePhotoPath,
    String? tryOnPhotoPath,
    String? afterPhotoPath,
    String? note,
    double? price,
    String? serviceName,
  }) async {
    final session = NailSession(
      id: const Uuid().v4(),
      clientId: clientId,
      beforePhotoPath: beforePhotoPath,
      tryOnPhotoPath: tryOnPhotoPath,
      afterPhotoPath: afterPhotoPath,
      note: note,
      price: price ?? defaultPrice,
      serviceName: serviceName ?? 'Маникюр',
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

  /// Получить ВСЕ сессии (для статистики и напоминаний)
  static List<NailSession> getAllSessions() {
    final list = <NailSession>[];
    for (final key in _sessions.keys) {
      final map = _sessions.get(key);
      if (map != null) {
        list.add(NailSession.fromMap(Map<String, dynamic>.from(map)));
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Обновить сессию (добавить фото, цену, заметку)
  static Future<void> updateSession(NailSession session) async {
    await _sessions.put(session.id, session.toMap());
  }

  /// Удалить сессию
  static Future<void> deleteSession(String id) async {
    final map = _sessions.get(id);
    if (map != null) {
      final session = NailSession.fromMap(Map<String, dynamic>.from(map));
      // Удаляем все файлы фото
      for (final path in [
        session.beforePhotoPath,
        session.tryOnPhotoPath,
        session.afterPhotoPath,
      ]) {
        if (path != null) {
          final file = File(path);
          if (await file.exists()) await file.delete();
        }
      }
    }
    await _sessions.delete(id);
  }

  // ============ МОИ ДИЗАЙНЫ (коллекция) ============

  /// Добавить дизайн в коллекцию
  static Future<void> addMyDesign(MyDesign design) async {
    await _myDesigns.put(design.id, design.toMap());
  }

  /// Получить все дизайны коллекции
  static List<MyDesign> getMyDesigns() {
    final list = <MyDesign>[];
    for (final key in _myDesigns.keys) {
      final map = _myDesigns.get(key);
      if (map != null) {
        list.add(MyDesign.fromMap(Map<String, dynamic>.from(map)));
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Удалить дизайн из коллекции
  static Future<void> deleteMyDesign(String id) async {
    final map = _myDesigns.get(id);
    if (map != null) {
      final design = MyDesign.fromMap(Map<String, dynamic>.from(map));
      // Если картинка — удаляем файл
      if (design.imagePath != null) {
        final file = File(design.imagePath!);
        if (await file.exists()) await file.delete();
      }
    }
    await _myDesigns.delete(id);
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

    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.png';
    final savedFile = await sourceFile.copy('${photosDir.path}/$fileName');
    return savedFile.path;
  }
}