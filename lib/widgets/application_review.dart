import 'package:flutter/material.dart';

import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/widgets/stored_image.dart';

Future<void> showWorkerApplicationReview({
  required BuildContext context,
  required WorkerApplication application,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final height = MediaQuery.sizeOf(context).height * 0.9;
      return SizedBox(
        height: height,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            const Text(
              'Worker application',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              'Review every submitted detail before you approve.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Center(
              child: _ReviewPhoto(
                url: application.profileImageUrl,
                label: 'Profile photo',
                size: 112,
                round: true,
              ),
            ),
            const SizedBox(height: 18),
            _ReviewRow(label: 'Full name', value: application.name),
            _ReviewRow(label: 'Mobile', value: application.phone),
            _ReviewRow(label: 'Gender', value: application.gender),
            _ReviewRow(
              label: 'Date of birth',
              value: _formatDob(application.dateOfBirth),
            ),
            _ReviewRow(
              label: 'Citizenship number',
              value: application.citizenshipNumber,
            ),
            _ReviewRow(label: 'District', value: application.district),
            _ReviewRow(label: 'Municipality', value: application.municipality),
            _ReviewRow(
              label: 'Specialties',
              value: application.specialtyLabel,
            ),
            _ReviewRow(
              label: 'Experience (years)',
              value: application.experienceYears,
            ),
            _ReviewRow(label: 'Status', value: application.status),
            const SizedBox(height: 12),
            const Text(
              'Identity documents',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ReviewPhoto(
                    url: application.citizenshipFrontUrl,
                    label: 'Citizenship front',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ReviewPhoto(
                    url: application.citizenshipBackUrl,
                    label: 'Citizenship back',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showOfficialApplicationReview({
  required BuildContext context,
  required AccessRequest request,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final height = MediaQuery.sizeOf(context).height * 0.82;
      return SizedBox(
        height: height,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            const Text(
              'Official application',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              'Verify identity and office details before you approve.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Center(
              child: _ReviewPhoto(
                url: request.profileImageUrl,
                label: 'Profile photo',
                size: 112,
                round: true,
              ),
            ),
            const SizedBox(height: 18),
            _ReviewRow(label: 'Full name', value: request.name),
            _ReviewRow(label: 'Official email', value: request.email),
            _ReviewRow(label: 'Mobile', value: request.phone),
            _ReviewRow(
              label: 'Employee / department ID',
              value: request.employeeId,
            ),
            _ReviewRow(label: 'Department', value: request.department),
            _ReviewRow(
              label: 'Municipality / ward',
              value: request.municipality,
            ),
            _ReviewRow(label: 'Status', value: request.status),
          ],
        ),
      );
    },
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = (value == null || value!.trim().isEmpty)
        ? 'Not provided'
        : value!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ReviewPhoto extends StatelessWidget {
  const _ReviewPhoto({
    required this.url,
    required this.label,
    this.size,
    this.round = false,
  });

  final String? url;
  final String label;
  final double? size;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final image = StoredImage.provider(url);
    final box = GestureDetector(
      onTap: image == null
          ? null
          : () => showDialog<void>(
              context: context,
              builder: (context) => Dialog(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: StoredImage(url, fit: BoxFit.contain),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
      child: Container(
        height: size ?? 140,
        width: size,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(round ? 80 : 14),
          border: Border.all(color: const Color(0xFFA5D6A7)),
          image: image == null
              ? null
              : DecorationImage(image: image, fit: BoxFit.cover),
        ),
        child: image == null
            ? const Center(
                child: Icon(
                  Icons.hide_image_outlined,
                  color: Color(0xFF2E7D32),
                ),
              )
            : null,
      ),
    );
    return Column(
      children: [
        box,
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}

String _formatDob(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
}
