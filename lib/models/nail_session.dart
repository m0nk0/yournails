/// Модель сессии (визита) клиента: фото "до", "примерка", "после".
class NailSession {
  final String id;
  final String clientId;
  final String? beforePhotoPath;  // Фото "до"
  final String? tryOnPhotoPath;   // Фото примерки
  final String? afterPhotoPath;   // Фото "после"
  final String? note;
  final double? price;            // НОВОЕ: сумма визита в ₽
  final String? serviceName;      // НОВОЕ: название услуги (дефолт "Маникюр")
  final DateTime createdAt;

  NailSession({
    required this.id,
    required this.clientId,
    this.beforePhotoPath,
    this.tryOnPhotoPath,
    this.afterPhotoPath,
    this.note,
    this.price,
    this.serviceName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'beforePhotoPath': beforePhotoPath,
      'tryOnPhotoPath': tryOnPhotoPath,
      'afterPhotoPath': afterPhotoPath,
      'note': note,
      'price': price,
      'serviceName': serviceName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NailSession.fromMap(Map<String, dynamic> map) {
    return NailSession(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      beforePhotoPath: map['beforePhotoPath'] as String?,
      tryOnPhotoPath: map['tryOnPhotoPath'] as String?,
      afterPhotoPath: map['afterPhotoPath'] as String?,
      note: map['note'] as String?,
      price: (map['price'] as num?)?.toDouble(),
      serviceName: map['serviceName'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  bool get hasBefore => beforePhotoPath != null && beforePhotoPath!.isNotEmpty;
  bool get hasTryOn => tryOnPhotoPath != null && tryOnPhotoPath!.isNotEmpty;
  bool get hasAfter => afterPhotoPath != null && afterPhotoPath!.isNotEmpty;

  /// Название услуги с дефолтом
  String get service => serviceName ?? 'Маникюр';

  /// Создать копию с изменёнными полями
  NailSession copyWith({
    String? id,
    String? clientId,
    String? beforePhotoPath,
    String? tryOnPhotoPath,
    String? afterPhotoPath,
    String? note,
    double? price,
    String? serviceName,
    DateTime? createdAt,
  }) {
    return NailSession(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      beforePhotoPath: beforePhotoPath ?? this.beforePhotoPath,
      tryOnPhotoPath: tryOnPhotoPath ?? this.tryOnPhotoPath,
      afterPhotoPath: afterPhotoPath ?? this.afterPhotoPath,
      note: note ?? this.note,
      price: price ?? this.price,
      serviceName: serviceName ?? this.serviceName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}