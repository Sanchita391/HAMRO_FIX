import 'package:flutter/material.dart';

import 'package:hamro_fix/screens/auth/landing_page.dart';

/// Full-screen civic chrome for Official / Admin web auth pages.
class StaffAuthShell extends StatelessWidget {
  const StaffAuthShell({
    super.key,
    required this.child,
    this.onBack,
  });

  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Theme(
      data: kHamroFixLightGreenTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FBF7),
        body: wide
            ? Row(
                children: [
                  const Expanded(flex: 5, child: _BrandPane(wide: true)),
                  Expanded(flex: 6, child: _formSide()),
                ],
              )
            : Column(
                children: [
                  const _BrandPane(wide: false),
                  Expanded(child: _formSide()),
                ],
              ),
      ),
    );
  }

  Widget _formSide() {
    return ColoredBox(
      color: const Color(0xFFF7FBF7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onBack != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onBack,
                child: const Text('Back'),
              ),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BrandPane extends StatelessWidget {
  const _BrandPane({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1A3D1A),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(wide ? 48 : 24, 28, wide ? 48 : 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (wide) const Spacer(),
              const HamroFixLogoBadge(size: 88, padding: 14),
              const SizedBox(height: 18),
              Text(
                'HamroFix',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: wide ? 36 : 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Making Communities Better, Together.',
                style: TextStyle(
                  color: Color(0xFFC8E6C9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Secure management access for authorised Officials and Administrators.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.45,
                ),
              ),
              if (wide) const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
