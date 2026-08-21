/// Модель сессии (записи) клиента: фото "до" и "после".
class NailSession {
  final String id;
  final String clientId;
  final String? beforePhotoPath;  // Путь к фото "до"
  final String? afterPhotoPath;   // Путь к фото "после"
  final String? note;              // Заметка мастера
  final DateTime createdAt;

  NailSession({
    required this.id,
    required this.clientId,
    this.beforePhotoPath,
    this.afterPhotoPath,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'beforePhotoPath': beforePhotoPath,
      'afterPhotoPath': afterPhotoPath,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NailSession.fromMap(Map<String, dynamic> map) {
    return NailSession(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      beforePhotoPath: map['beforePhotoPath'] as String?,
      afterPhotoPath: map['afterPhotoPath'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Есть ли фото "до"
  bool get hasBefore => beforePhotoPath != null && beforePhotoPath!.isNotEmpty;

  /// Есть ли фото "после"
  bool get hasAfter => afterPhotoPath != null && afterPhotoPath!.isNotEmpty;
}