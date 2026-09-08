/// Модель манифеста библиотеки дизайнов.
/// Содержит метаданные о версии и составе встроенной библиотеки.
class LibraryManifest {
  final int version;
  final int colorCount;
  final int materialCount;
  final int patternCount;
  final List<String> colorGroups;
  final DateTime lastUpdated;

  LibraryManifest({
    required this.version,
    required this.colorCount,
    required this.materialCount,
    required this.patternCount,
    required this.colorGroups,
    required this.lastUpdated,
  });

  /// Создать копию с изменёнными полями
  LibraryManifest copyWith({
    int? version,
    int? colorCount,
    int? materialCount,
    int? patternCount,
    List<String>? colorGroups,
    DateTime? lastUpdated,
  }) {
    return LibraryManifest(
      version: version ?? this.version,
      colorCount: colorCount ?? this.colorCount,
      materialCount: materialCount ?? this.materialCount,
      patternCount: patternCount ?? this.patternCount,
      colorGroups: colorGroups ?? this.colorGroups,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory LibraryManifest.fromJson(Map<String, dynamic> json) {
    return LibraryManifest(
      version: json['version'] as int? ?? 1,
      colorCount: json['colorCount'] as int? ?? 0,
      materialCount: json['materialCount'] as int? ?? 0,
      patternCount: json['patternCount'] as int? ?? 0,
      colorGroups: json['colorGroups'] != null 
          ? List<String>.from(json['colorGroups'] as List) 
          : [],
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'colorCount': colorCount,
      'materialCount': materialCount,
      'patternCount': patternCount,
      'colorGroups': colorGroups,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}