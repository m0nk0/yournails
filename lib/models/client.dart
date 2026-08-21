/// Модель клиента.
class Client {
  final String id;
  final String name;
  final String? phone;
  final DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    this.phone,
    required this.createdAt,
  });

  /// Конвертация в Map для хранения в Hive
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Восстановление из Map
  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}