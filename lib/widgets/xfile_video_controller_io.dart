import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

VideoPlayerController createXFileVideoController(XFile file) {
  return VideoPlayerController.file(File(file.path));
}
