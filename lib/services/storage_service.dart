import 'dart:convert';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

/// Stores photos inside Firestore as compressed data URIs.
/// Firebase Storage is not used.
class StorageService {
  Future<String> uploadXFile({
    required String path,
    required XFile file,
  }) async {
    final encoded = await encodeImage(file);
    if (encoded == null) {
      throw const FormatException('This photo is too large to save in Firestore.');
    }
    return encoded;
  }

  Future<String?> encodeImage(
    XFile file, {
    int maxWidth = 480,
    int maxBytes = 350000,
  }) async {
    final name = file.name.toLowerCase();
    final mime = (file.mimeType ?? '').toLowerCase();
    if (name.endsWith('.mp4') ||
        name.endsWith('.mov') ||
        mime.startsWith('video/')) {
      return null;
    }

    var width = maxWidth;
    while (width >= 120) {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: width,
      );
      final frame = await codec.getNextFrame();
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      if (png == null) return null;
      final data = png.buffer.asUint8List();
      if (data.length <= maxBytes) {
        return 'data:image/png;base64,${base64Encode(data)}';
      }
      width = (width * 0.65).round();
    }
    return null;
  }
}
