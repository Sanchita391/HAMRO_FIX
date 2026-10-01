import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:hamro_fix/widgets/xfile_video_controller_stub.dart'
    if (dart.library.io) 'package:hamro_fix/widgets/xfile_video_controller_io.dart'
    if (dart.library.html) 'package:hamro_fix/widgets/xfile_video_controller_web.dart';

class XFileVideoPreview extends StatefulWidget {
  const XFileVideoPreview({
    super.key,
    required this.file,
    this.width,
    this.height = 200,
  });

  final XFile file;
  final double? width;
  final double height;

  @override
  State<XFileVideoPreview> createState() => _XFileVideoPreviewState();
}

class _XFileVideoPreviewState extends State<XFileVideoPreview> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant XFileVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path ||
        oldWidget.file.name != widget.file.name) {
      _controller?.dispose();
      _controller = null;
      _load();
    }
  }

  Future<void> _load() async {
    final controller = createXFileVideoController(widget.file);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() => _error = 'Video preview could not start.');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggle() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: ColoredBox(
          color: const Color(0xFF1B5E20),
          child: Center(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const ColoredBox(
          color: Colors.black,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }
    final playing = controller.value.isPlaying;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Material(
        color: Colors.black,
        child: InkWell(
          onTap: _toggle,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width == 0
                      ? 16
                      : controller.value.size.width,
                  height: controller.value.size.height == 0
                      ? 9
                      : controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
              if (!playing)
                const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 64,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
