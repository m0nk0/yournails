/// Модель зоны ногтя на фото.
class NailZone {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final int fingerIndex;

  NailZone({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.fingerIndex = 0,
  });

  NailZone copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? fingerIndex,
  }) {
    return NailZone(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      fingerIndex: fingerIndex ?? this.fingerIndex,
    );
  }
}