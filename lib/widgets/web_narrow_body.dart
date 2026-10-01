import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hamro_fix/core/theme/app_theme.dart';

/// Keeps web forms and buttons from stretching across a wide monitor.
class WebNarrowBody extends StatelessWidget {
  const WebNarrowBody({
    super.key,
    required this.child,
    this.maxWidth = 560,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// AppBar page with a centered desktop column.
class WebPageScaffold extends StatelessWidget {
  const WebPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.maxWidth = 640,
  });

  final String title;
  final Widget body;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HamroFixTheme.canvas,
      appBar: AppBar(title: Text(title)),
      body: WebNarrowBody(maxWidth: maxWidth, child: body),
    );
  }
}
