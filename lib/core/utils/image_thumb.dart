import 'dart:typed_data';

import 'package:image/image.dart' as img;

({Uint8List bytes, int width, int height})? makeImageThumb(
  Uint8List source, {
  int maxSide = 320,
}) {
  final decoded = img.decodeImage(source);
  if (decoded == null) return null;
  final oriented = img.bakeOrientation(decoded);
  final w = oriented.width;
  final h = oriented.height;
  if (w <= 0 || h <= 0) return null;
  final longest = w > h ? w : h;
  final resized = longest <= maxSide
      ? oriented
      : img.copyResize(
          oriented,
          width: (w * maxSide / longest).round(),
          height: (h * maxSide / longest).round(),
        );
  final bytes = img.encodeJpg(resized, quality: 70);
  if (bytes.isEmpty) return null;
  return (
    bytes: Uint8List.fromList(bytes),
    width: resized.width,
    height: resized.height,
  );
}
