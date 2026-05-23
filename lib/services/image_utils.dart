import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Runs the full image preparation pipeline in a background isolate.
/// Returns null if decoding fails.
Future<img.Image?> prepareImageForPrint(
  Uint8List bytes,
  int targetWidth, {
  int maxHeight = 800,
}) async {
  final result = await compute(_isolatePrepare, {
    'bytes': bytes,
    'targetWidth': targetWidth,
    'maxHeight': maxHeight,
  });

  final data = result['data'] as Uint8List;
  if (data.isEmpty) return null;

  final w = result['width'] as int;
  final h = result['height'] as int;
  return img.Image.fromBytes(w, h, data);
}

// Top-level so compute() can call it in a separate isolate.
Map<String, dynamic> _isolatePrepare(Map<String, dynamic> params) {
  final bytes = params['bytes'] as Uint8List;
  final targetWidth = params['targetWidth'] as int;
  final maxHeight = params['maxHeight'] as int;

  final decoded = img.decodeImage(bytes);
  if (decoded == null) return {'width': 0, 'height': 0, 'data': Uint8List(0)};

  final oriented = img.bakeOrientation(decoded);
  var resized = img.copyResize(oriented, width: targetWidth);
  if (resized.height > maxHeight) {
    resized = img.copyResize(resized, height: maxHeight);
  }

  final gray = img.grayscale(resized);
  final dithered = _floydSteinberg(gray);

  return {
    'width': dithered.width,
    'height': dithered.height,
    'data': Uint8List.fromList(dithered.getBytes(format: img.Format.rgba)),
  };
}

/// Floyd-Steinberg error-diffusion dither to pure black/white.
/// Input must be a grayscale [img.Image].
img.Image _floydSteinberg(img.Image src) {
  final w = src.width;
  final h = src.height;

  // Float buffer for error accumulation — one value per pixel.
  final buf = Float64List(w * h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      buf[y * w + x] = img.getRed(src.getPixel(x, y)).toDouble();
    }
  }

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final idx = y * w + x;
      final old = buf[idx].clamp(0.0, 255.0);
      final neu = old < 128.0 ? 0.0 : 255.0;
      buf[idx] = neu;
      final err = old - neu;

      if (x + 1 < w) buf[idx + 1] += err * 7.0 / 16.0;
      if (y + 1 < h) {
        if (x > 0) buf[idx + w - 1] += err * 3.0 / 16.0;
        buf[idx + w] += err * 5.0 / 16.0;
        if (x + 1 < w) buf[idx + w + 1] += err * 1.0 / 16.0;
      }
    }
  }

  final result = img.Image(w, h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final v = buf[y * w + x].round().clamp(0, 255);
      result.setPixel(x, y, img.getColor(v, v, v, 255));
    }
  }
  return result;
}
