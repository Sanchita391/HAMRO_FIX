import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:hamro_fix/services/video_storage_service.dart';
import 'package:hamro_fix/widgets/video_bytes_controller_stub.dart'
    if (dart.library.io) 'package:hamro_fix/widgets/video_bytes_controller_io.dart'
    if (dart.library.html) 'package:hamro_fix/widgets/video_bytes_controller_web.dart';

class StoredVideo extends StatefulWidget {
  const StoredVideo(this.url, {super.key, this.height = 220});

  final String? url;
  final double height;

  @override
  State<StoredVideo> createState() => _StoredVideoState();
}

class _StoredVideoState extends State<StoredVideo> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StoredVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller?.removeListener(_tick);
      _controller?.dispose();
      _controller = null;
      _error = null;
      _load();
    }
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final url = widget.url;
    if (url == null || url.isEmpty) return;
    VideoPlayerController? controller;
    try {
      if (VideoStorageService.isChunkedRef(url)) {
        final bytes = await VideoStorageService().loadBytes(url);
        controller = await controllerFromVideoBytes(bytes);
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      }
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      controller.addListener(_tick);
      setState(() => _controller = controller);
    } catch (_) {
      await controller?.dispose();
      if (mounted) {
        setState(() => _error = 'Video could not be played.');
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_tick);
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
    if (widget.url == null || widget.url!.isEmpty) {
      return SizedBox(height: widget.height);
    }
    if (_error != null) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: ColoredBox(
          color: const Color(0xFF1B5E20),
          child: Center(
            child: Text(_error!, style: const TextStyle(color: Colors.white)),
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: const ColoredBox(
          color: Colors.black,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }
    final playing = controller.value.isPlaying;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
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
