/// Модель сессии (визита) клиента: фото "до", "примерка", "после".
class NailSession {
  final String id;
  final String clientId;
  final String? beforePhotoPath;  // Фото "до"
  final String? tryOnPhotoPath;   // Фото примерки
  final String? afterPhotoPath;   // Фото "после"
  final String? note;
  final DateTime createdAt;

  NailSession({
    required this.id,
    required this.clientId,
    this.beforePhotoPath,
    this.tryOnPhotoPath,
    this.afterPhotoPath,
    this.note,
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
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  bool get hasBefore => beforePhotoPath != null && beforePhotoPath!.isNotEmpty;
  bool get hasTryOn => tryOnPhotoPath != null && tryOnPhotoPath!.isNotEmpty;
  bool get hasAfter => afterPhotoPath != null && afterPhotoPath!.isNotEmpty;
}