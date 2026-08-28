// lib/models/master.dart

/// Модель мастера маникюра
class Master {
  final String id;
  final String name;
  
  /// Путь к логотипу (если isCustomIcon = true)
  final String? iconPath;
  
  /// Название Material Icon (если isCustomIcon = false)
  final String? iconName;
  
  /// Флаг: своя картинка или иконка из набора
  final bool isCustomIcon;
  
  final DateTime createdAt;

  Master({
    required this.id,
    required this.name,
    this.iconPath,
    this.iconName,
    this.isCustomIcon = false,
    required this.createdAt,
  });

  /// Конвертация в Map для хранения в Hive
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconPath': iconPath,
      'iconName': iconName,
      'isCustomIcon': isCustomIcon,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Восстановление из Map
  factory Master.fromMap(Map<String, dynamic> map) {
    return Master(
      id: map['id'] as String,
      name: map['name'] as String,
      iconPath: map['iconPath'] as String?,
      iconName: map['iconName'] as String?,
      isCustomIcon: map['isCustomIcon'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}