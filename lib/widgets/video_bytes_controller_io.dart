import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

Future<VideoPlayerController> controllerFromVideoBytes(Uint8List bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/hamrofix_play_${DateTime.now().millisecondsSinceEpoch}.mp4',
  );
  await file.writeAsBytes(bytes, flush: true);
  return VideoPlayerController.file(file);
}
