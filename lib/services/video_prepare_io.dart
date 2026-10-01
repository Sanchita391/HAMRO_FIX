import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

Future<XFile> preparePublicVideo(XFile file) async {
  try {
    final local = await _localMp4(file);
    final media = await VideoCompress.compressVideo(
      local.path,
      quality: VideoQuality.LowQuality,
      deleteOrigin: false,
      includeAudio: true,
      frameRate: 24,
    );
    final out = media?.file;
    if (out == null) return local;
    return XFile(out.path, mimeType: 'video/mp4', name: 'clip.mp4');
  } catch (_) {
    try {
      return await _localMp4(file);
    } catch (_) {
      return file;
    }
  }
}

Future<XFile> _localMp4(XFile file) async {
  final path = file.path;
  if (path.isNotEmpty &&
      !path.startsWith('content://') &&
      File(path).existsSync()) {
    return file;
  }
  final bytes = await file.readAsBytes();
  final dir = await getTemporaryDirectory();
  final dest = File(
    '${dir.path}/hamrofix_${DateTime.now().millisecondsSinceEpoch}.mp4',
  );
  await dest.writeAsBytes(bytes, flush: true);
  return XFile(dest.path, mimeType: 'video/mp4', name: 'clip.mp4');
}
