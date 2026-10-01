import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Preview a picked photo on phone and in the browser (no dart:io).
class XFilePreview extends StatelessWidget {
  const XFilePreview({
    super.key,
    required this.file,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final XFile file;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final name = file.name.toLowerCase();
    final mime = (file.mimeType ?? '').toLowerCase();
    final isVideo =
        mime.startsWith('video/') ||
        name.endsWith('.mp4') ||
        name.endsWith('.mov') ||
        name.endsWith('.webm');
    if (isVideo) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFF1B5E20),
        alignment: Alignment.center,
        child: const Icon(Icons.videocam, color: Colors.white, size: 48),
      );
    }
    return FutureBuilder(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Image.memory(
          snapshot.data!,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }
}

class XFileCircleImage extends StatelessWidget {
  const XFileCircleImage({
    super.key,
    required this.file,
    required this.radius,
    this.placeholder,
  });

  final XFile file;
  final double radius;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: const Color(0xFFE8F5E9),
            child: placeholder,
          );
        }
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(snapshot.data!),
        );
      },
    );
  }
}
