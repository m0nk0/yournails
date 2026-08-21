/// Модель материала с визуальными эффектами.
class NailMaterial {
  final String id;
  final String name;
  final String description;
  
  // Визуальные параметры
  final double opacity;        // Прозрачность (0.0 - 1.0)
  final double saturation;     // Насыщенность (0.0 - 1.0)
  final bool hasGloss;         // Есть ли глянец
  final double glossIntensity; // Интенсивность блика (0.0 - 1.0)

  NailMaterial({
    required this.id,
    required this.name,
    required this.description,
    this.opacity = 1.0,
    this.saturation = 1.0,
    this.hasGloss = true,
    this.glossIntensity = 0.5,
  });
}