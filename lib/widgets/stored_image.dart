import 'dart:convert';

import 'package:flutter/material.dart';

class StoredImage extends StatelessWidget {
  const StoredImage(
    this.value, {
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  final String? value;
  final double? height;
  final double? width;
  final BoxFit fit;

  static final Map<String, ImageProvider> _cache = {};

  static ImageProvider? provider(String? value) {
    if (value == null || value.isEmpty) return null;
    final cached = _cache[value];
    if (cached != null) return cached;
    ImageProvider image;
    if (value.startsWith('data:image')) {
      final comma = value.indexOf(',');
      if (comma < 0) return null;
      image = MemoryImage(base64Decode(value.substring(comma + 1)));
    } else if (value.startsWith('http://') || value.startsWith('https://')) {
      image = NetworkImage(value);
    } else {
      try {
        image = MemoryImage(base64Decode(value));
      } catch (_) {
        return null;
      }
    }
    _cache[value] = image;
    return image;
  }

  @override
  Widget build(BuildContext context) {
    final image = provider(value);
    if (image == null) {
      return SizedBox(
        height: height,
        width: width,
        child: const ColoredBox(color: Color(0xFFE8F5E9)),
      );
    }
    return Image(
      image: image,
      height: height,
      width: width,
      fit: fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return child;
      },
      errorBuilder: (_, __, ___) => SizedBox(
        height: height,
        width: width,
        child: const ColoredBox(color: Color(0xFFE8F5E9)),
      ),
    );
  }
}
