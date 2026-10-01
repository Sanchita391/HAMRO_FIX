import 'package:flutter/material.dart';

import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/widgets/stored_video.dart';

class ReportVideoPlayer extends StatelessWidget {
  const ReportVideoPlayer(
    this.report, {
    super.key,
    this.height = 200,
  });

  final ReportIssue report;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = report.playableVideoUrl;
    if (url == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: StoredVideo(url, height: height),
      ),
    );
  }
}
