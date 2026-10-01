import 'dart:typed_data';

import 'package:video_player/video_player.dart';

Future<VideoPlayerController> controllerFromVideoBytes(Uint8List bytes) async {
  return VideoPlayerController.networkUrl(
    Uri.dataFromBytes(bytes, mimeType: 'video/mp4'),
  );
}
