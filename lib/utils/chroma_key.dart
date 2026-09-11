import 'dart:async';
import 'dart:io' show zlib;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Chroma-key «убрать белый фон» при импорте картинки-узора.
///
/// Работает ОДИН РАЗ на этапе загрузки: белые и почти белые нейтральные
/// пиксели становятся прозрачными, граница фона — мягкий полупрозрачный край.
/// Сохраняется готовый PNG: на рендер дальше ноль затрат.
///
/// Реализация без decodeImageFromPixels: PNG кодируется вручную
/// (zlib + CRC32), декодирование и чтение пикселей — стандартные
/// decodeImageFromList / toByteData (те же, что в пипетке кутикулы).
class ChromaKey {
  ChromaKey._();

  /// Принимает байты PNG/JPEG, возвращает байты PNG с прозрачным фоном.
  /// Любая ошибка обработки = исходные байты (без краха).
  static Future<Uint8List> removeWhiteBackground(Uint8List bytes) async {
    try {
      // 1) Декодируем исходник
      final Completer<ui.Image> dec = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image image) {
        dec.complete(image);
      });
      final ui.Image img = await dec.future;

      // 2) Читаем сырые RGBA-пиксели
      final ByteData? raw =
          await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (raw == null) {
        img.dispose();
        return bytes;
      }
      final Uint8List px = raw.buffer.asUint8List();
      final int w = img.width;
      final int h = img.height;
      img.dispose();

      // 3) Обесцвечиваем белый/почти белый нейтральный фон
      for (int i = 0; i < px.length; i += 4) {
        final double r = px[i].toDouble();
        final double g = px[i + 1].toDouble();
        final double b = px[i + 2].toDouble();

        // Яркость и «нейтральность»: белый фон = каналы высокие и близкие
        final double lum = (r + g + b) / 3;
        final double maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
        final double minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
        if ((maxC - minC) >= 40) continue; // цветные пиксели не трогаем

        if (lum >= 245) {
          px[i + 3] = 0; // чистый белый → дырка
        } else if (lum >= 200) {
          // мягкий край: чем ближе к белому, тем прозрачнее
          final double t = (lum - 200) / 45; // 0..1
          px[i + 3] = (255 * (1 - t)).round().clamp(0, 255);
        }
      }

      // 4) Кодируем PNG вручную
      return _encodePng(px, w, h);
    } catch (_) {
      return bytes;
    }
  }

  // ============ МИНИМАЛЬНЫЙ PNG-ЭНКОДЕР (RGBA 8 bit) ============

  static Uint8List _encodePng(Uint8List rgba, int w, int h) {
    // Scanlines: байт фильтра 0 + строка пикселей
    final BytesBuilder scan = BytesBuilder(copy: false);
    for (int y = 0; y < h; y++) {
      scan.addByte(0);
      scan.add(rgba.sublist(y * w * 4, (y + 1) * w * 4));
    }
    final Uint8List idat = zlib.encode(scan.toBytes()) as Uint8List;

    final BytesBuilder out = BytesBuilder(copy: false);
    // Сигнатура PNG
    out.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

    // IHDR: ширина, высота, depth 8, colorType 6 (RGBA), сжатие 0, фильтр 0, interlace 0
    final ByteData ihdr = ByteData(13);
    ihdr.setUint32(0, w);
    ihdr.setUint32(4, h);
    ihdr.setUint8(8, 8); // bit depth
    ihdr.setUint8(9, 6); // color type RGBA
    ihdr.setUint8(10, 0);
    ihdr.setUint8(11, 0);
    ihdr.setUint8(12, 0);
    _writeChunk(out, 'IHDR', ihdr.buffer.asUint8List());

    _writeChunk(out, 'IDAT', idat);
    _writeChunk(out, 'IEND', Uint8List(0));

    return out.toBytes();
  }

  static void _writeChunk(BytesBuilder out, String type, Uint8List data) {
    final ByteData len = ByteData(4)..setUint32(0, data.length);
    out.add(len.buffer.asUint8List());

    final Uint8List typeBytes =
        Uint8List.fromList(type.codeUnits); // ASCII: IHDR/IDAT/IEND
    out.add(typeBytes);
    out.add(data);

    // CRC32 считается по type + data
    final Uint8List crcInput = Uint8List(typeBytes.length + data.length)
      ..setRange(0, typeBytes.length, typeBytes)
      ..setRange(typeBytes.length, typeBytes.length + data.length, data);
    final ByteData crc = ByteData(4)..setUint32(0, _crc32(crcInput));
    out.add(crc.buffer.asUint8List());
  }

  static final List<int> _crcTable = _buildCrcTable();

  static List<int> _buildCrcTable() {
    final List<int> t = List<int>.filled(256, 0);
    for (int n = 0; n < 256; n++) {
      int c = n;
      for (int k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
      }
      t[n] = c;
    }
    return t;
  }

  static int _crc32(Uint8List bytes) {
    int c = 0xFFFFFFFF;
    for (int i = 0; i < bytes.length; i++) {
      c = _crcTable[(c ^ bytes[i]) & 0xFF] ^ (c >> 8);
    }
    return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}