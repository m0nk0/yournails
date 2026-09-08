/// JSON-представление встроенной библиотеки по умолчанию.
/// Содержит материалы и паттерны. Цвета загружаются отдельно из builtin_colors.dart.
const String defaultLibraryJson = '''
{
  "manifest": {
    "version": 1,
    "colorCount": 60,
    "materialCount": 5,
    "patternCount": 7,
    "colorGroups": [
      "Красные",
      "Розовые",
      "Нюд",
      "Фиолетовые",
      "Синие",
      "Зелёные",
      "Жёлтые",
      "Тёмные",
      "Мои цвета"
    ],
    "lastUpdated": "2026-09-07T00:00:00.000Z"
  },
  "colors": [],
  "materials": [
    {
      "id": "mat_gel_polish",
      "name": "Гель-лак",
      "description": "Классическое глянцевое покрытие",
      "opacity": 1.0,
      "saturation": 1.0,
      "hasGloss": true,
      "glossIntensity": 0.8
    },
    {
      "id": "mat_gel",
      "name": "Гель",
      "description": "Плотное покрытие с высоким глянцем",
      "opacity": 1.0,
      "saturation": 1.0,
      "hasGloss": true,
      "glossIntensity": 0.9
    },
    {
      "id": "mat_acrylic",
      "name": "Акрил",
      "description": "Матовое или полуматовое плотное покрытие",
      "opacity": 0.95,
      "saturation": 0.9,
      "hasGloss": false,
      "glossIntensity": 0.2
    },
    {
      "id": "mat_biogel",
      "name": "Биогель",
      "description": "Натуральный вид, полупрозрачный",
      "opacity": 0.8,
      "saturation": 0.8,
      "hasGloss": true,
      "glossIntensity": 0.6
    },
    {
      "id": "mat_regular",
      "name": "Обычный лак",
      "description": "Стандартное лаковое покрытие",
      "opacity": 0.9,
      "saturation": 0.9,
      "hasGloss": true,
      "glossIntensity": 0.7
    }
  ],
  "patterns": [
    { "type": "none", "colorValue": 4294967295 },
    { "type": "french", "colorValue": 4294967295 },
    { "type": "ombre", "colorValue": 4294967295 },
    { "type": "stripes", "colorValue": 4294967295 },
    { "type": "dots", "colorValue": 4294967295 },
    { "type": "marble", "colorValue": 4294967295 },
    { "type": "glitter", "colorValue": 4294967295 }
  ]
}
''';