/// Модель клиента.
class Client {
  final String id;
  final String name;
  final String? phone;
  final String? note;  // НОВОЕ: постоянная заметка (аллергии, предпочтения)
  final DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    this.phone,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Создать копию с изменёнными полями
  Client copyWith({
    String? id,
    String? name,
    String? phone,
    String? note,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}