import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/auth_services.dart';

Future<void> showStaffLoginInvite({
  required BuildContext context,
  required String name,
  required String email,
  required String roleLabel,
  String? temporaryPassword,
  String? extraLine,
}) async {
  final auth = AuthServices();
  final body = auth.staffWelcomeMessage(
    name: name,
    email: email,
    roleLabel: roleLabel,
    temporaryPassword: temporaryPassword,
    extraLine: extraLine,
  );
  try {
    if ((temporaryPassword ?? '').trim().isEmpty) {
      await auth.sendStaffLoginEmail(email);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthMessages.from(e))),
      );
    }
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$roleLabel login details',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'A password setup email was sent. You can also email or copy the sign-in details below.',
            ),
            const SizedBox(height: 12),
            SelectableText(body, style: const TextStyle(height: 1.45)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final uri = Uri(
                  scheme: 'mailto',
                  path: email,
                  query: _mailtoQuery({
                    'subject': 'Your HamroFix $roleLabel login',
                    'body': body,
                  }),
                );
                await launchUrl(uri);
              },
              child: const Text('Open email app'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: body));
                if (sheetContext.mounted) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(content: Text('Copied login details.')),
                  );
                }
              },
              child: const Text('Copy email and password'),
            ),
          ],
        ),
      );
    },
  );
}

String _mailtoQuery(Map<String, String> params) {
  return params.entries
      .map(
        (entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
      )
      .join('&');
}
