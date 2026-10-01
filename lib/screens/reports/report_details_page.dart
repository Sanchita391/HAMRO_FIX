import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hamro_fix/core/constants/app_constants.dart';
import 'package:hamro_fix/core/theme/app_theme.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/screens/dashboards/shared_tabs.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/auth_services.dart';
import 'package:hamro_fix/services/budget_service.dart';
import 'package:hamro_fix/services/location_service.dart';
import 'package:hamro_fix/services/report_service.dart';
import 'package:hamro_fix/services/task_service.dart';
import 'package:hamro_fix/widgets/stored_image.dart';
import 'package:hamro_fix/widgets/stored_video.dart';
import 'package:hamro_fix/widgets/xfile_video_preview.dart';
import 'package:hamro_fix/widgets/web_narrow_body.dart';
import 'package:hamro_fix/widgets/worker_payment.dart';

class ReportDetailsPage extends StatefulWidget {
  const ReportDetailsPage({
    super.key,
    required this.report,
    required this.profile,
  });

  final ReportIssue report;
  final UserProfile profile;

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  final _reports = ReportService();
  final _tasks = TaskService();
  bool _busy = false;

  UserProfile get profile => widget.profile;
  bool get isOfficial => profile.hasRole(UserRole.official);

  bool _canAddWorkers(ReportIssue report) {
    if (report.crewIds.isNotEmpty) {
      return report.status != ReportStatus.workCompleted &&
          report.status != ReportStatus.completed &&
          report.status != ReportStatus.publicFeed &&
          report.status != ReportStatus.verifiedFake &&
          report.status != ReportStatus.officialDeclined;
    }
    return report.status == ReportStatus.officialAccepted ||
        report.status == ReportStatus.verifiedValid ||
        report.status == ReportStatus.workerAssigned ||
        report.status == ReportStatus.workerInspection;
  }

  bool get isWorker => profile.hasRole(UserRole.worker);
  bool get isAdmin => profile.hasRole(UserRole.admin);
  bool get isPublic => profile.hasRole(UserRole.public);

  Future<void> _run(Future<void> Function() action, String done) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(done)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openMaps(ReportIssue report) async {
    if (!report.hasLocation) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${report.latitude},${report.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _reports.watchReport(widget.report.id),
      builder: (context, snapshot) {
        final report = snapshot.data?.exists == true
            ? ReportIssue.fromFirestore(snapshot.data!)
            : widget.report;
        return Scaffold(
          backgroundColor: HamroFixTheme.canvas,
          appBar: AppBar(title: Text(report.publicId)),
          body: WebNarrowBody(
            maxWidth: 720,
            child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (report.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: StoredImage(report.imageUrl, height: 200),
                ),
              if ((report.playableVideoUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: StoredVideo(report.playableVideoUrl, height: 220),
                ),
              ],
              const SizedBox(height: 12),
              SelectableText(
                report.publicId,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: HamroFixTheme.mediumGreen,
                ),
              ),
              Text(
                report.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(report.description),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(report.status.replaceAll('_', ' '))),
                  Chip(label: Text(report.category)),
                  if (report.municipality != null)
                    Chip(label: Text(report.municipality!)),
                  if (report.crewLabel.isNotEmpty)
                    Chip(label: Text('Workers: ${report.crewLabel}')),
                  if (report.isAnonymous)
                    const Chip(
                      label: Text('Anonymous'),
                      backgroundColor: Color(0xFFEEEEEE),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _ReporterPrivacyCard(report: report, profile: profile),
              if (report.hasLocation) ...[
                const SizedBox(height: 8),
                Text('GPS: ${report.latitude}, ${report.longitude}'),
                TextButton(
                  onPressed: () => _openMaps(report),
                  child: const Text('Open this spot on the map'),
                ),
              ],
              if (report.approvedBudgetAmount != null)
                Text(
                  'Final budget: NPR ${report.approvedBudgetAmount!.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              if (report.workerEvidenceImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Inspection photos',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final url in report.workerEvidenceImages)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: StoredImage(url, width: 90, height: 90),
                        ),
                    ],
                  ),
                ),
              ],
              if (report.workerEvidenceVideos.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Inspection videos',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final url in report.workerEvidenceVideos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: StoredVideo(url, height: 180),
                  ),
              ],
              StreamBuilder<List<String>>(
                stream: _reports.watchCompletionPhotos(report.id),
                builder: (context, photoSnap) {
                  final urls = <String>{
                    ...report.completionImages,
                    if (report.proofImageUrl != null) report.proofImageUrl!,
                    ...?photoSnap.data,
                  };
                  if (urls.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'Completed work',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final url in urls)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: StoredImage(url, width: 90, height: 90),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (report.inspectionItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Budget items from inspection',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                for (final item in report.inspectionItems)
                  Text(
                    '${item['name'] ?? 'Item'} × ${item['quantity'] ?? 0} @ NPR ${item['unitCost'] ?? 0}',
                  ),
                if (!isPublic) ...[
                  const SizedBox(height: 10),
                  WorkerPaymentSummary(
                    itemsTotal: report.taskBudget,
                    expectedPayment: WorkerPay.salaryOf(report.taskBudget),
                    expectedDays: report.expectedWorkDays,
                    salaryAsGrandTotal: isWorker,
                  ),
                ],
              ],
              const Divider(height: 32),
              if (isOfficial) ..._officialActions(report),
              if (isWorker && report.isAssignedTo(profile.uid))
                ..._workerActions(report),
              if (isAdmin) ..._adminActions(report),
              if (isPublic && report.uid == profile.uid)
                ..._publicActions(report),
              const SizedBox(height: 16),
              const Text(
                'Timeline',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              StreamBuilder(
                stream: _reports.watchTimeline(report.id),
                builder: (context, timelineSnap) {
                  final docs = timelineSnap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Text('No timeline events yet.');
                  }
                  return Column(
                    children: [
                      for (final doc in docs)
                        ListTile(
                          dense: true,
                          title: Text('${doc.data()['action'] ?? ''}'),
                          subtitle: Text('${doc.data()['message'] ?? ''}'),
                        ),
                    ],
                  );
                },
              ),
              if (_busy) const LinearProgressIndicator(),
            ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _officialActions(ReportIssue report) {
    final review =
        report.status == ReportStatus.submitted ||
        report.status == ReportStatus.officialReview;
    return [
      if (review) ...[
        FilledButton(
          onPressed: () => _run(
            () => _reports.officialDecision(
              report: report,
              status: ReportStatus.officialAccepted,
            ),
            'Report accepted. Assign a worker next.',
          ),
          child: const Text('Approve report'),
        ),
        TextButton(
          onPressed: () => _run(
            () => _reports.officialDecision(
              report: report,
              status: ReportStatus.officialDeclined,
              reason: 'Declined by official',
            ),
            'Report declined.',
          ),
          child: const Text('Decline'),
        ),
      ],
      if (_canAddWorkers(report))
        FilledButton(
          onPressed: () => _assignWorkers(report),
          child: Text(
            report.crewIds.isEmpty
                ? 'Assign workers to inspect'
                : 'Add more workers',
          ),
        ),
      if (report.workerVerification == 'fake' ||
          report.status == ReportStatus.verifiedFake)
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB71C1C),
            foregroundColor: Colors.white,
          ),
          onPressed: () => _run(
            () => _reports.confirmFakeAndBlacklist(
              report: report,
              reason: 'Official confirmed fake report ${report.publicId}',
            ),
            'Public user blacklisted for a fake report.',
          ),
          child: const Text('Confirm fake and blacklist public user'),
        ),
      if (report.status == ReportStatus.budgetApproved)
        FilledButton(
          onPressed: () => _run(
            () => _tasks.assignFundedTask(
              report: report,
              workerId: report.inspectorIds.isEmpty
                  ? ''
                  : report.inspectorIds.first,
              workerIds: report.inspectorIds,
              instructions:
                  'Complete funded work for ${report.publicId}. Approved budget NPR ${report.approvedBudgetAmount?.toStringAsFixed(0) ?? '0'}.',
            ),
            'Approved budget sent to the worker and the public reporter. They can post it now.',
          ),
          child: const Text('Send approved budget to worker & public'),
        )
      else if (report.isFundedBudgetSent)
        FilledButton(
          onPressed: null,
          child: const Text('Done · budget sent'),
        ),
      if (report.status == ReportStatus.workCompleted)
        FilledButton(
          onPressed: () => _run(
            () => _reports.shareCompletionWithPublic(report),
            'Completed photos sent to the public. They can post before and after on the same feed item.',
          ),
          child: const Text('Send completed photos to public'),
        ),
    ];
  }

  Future<void> _assignWorkers(ReportIssue report) async {
    final workers = await AuthServices().watchUsers().first;
    final approved = workers
        .where(
          (user) =>
              user.hasRole(UserRole.worker) &&
              user.isApproved &&
              !user.isRestricted,
        )
        .toList();
    if (!mounted) return;
    final selected = await showAssignWorkersSheet(
      context: context,
      workers: approved,
      selectedIds: report.crewIds,
      reportCategory: report.category,
    );
    if (selected == null || selected.isEmpty) return;
    await _run(
      () => _reports.assignWorkers(
        reportId: report.id,
        workerIds: selected.map((person) => person.uid).toList(),
        workerNames: selected.map((person) => person.name).toList(),
        report: report,
      ),
      report.crewIds.isEmpty
          ? 'Assigned ${selected.length} worker(s). The job is on their dashboards.'
          : 'Extra worker(s) added. They will see this task too.',
    );
  }

  List<Widget> _workerActions(ReportIssue report) {
    final inspect =
        report.status == ReportStatus.workerAssigned ||
        report.status == ReportStatus.workerInspection ||
        report.status == ReportStatus.officialAccepted;
    return [
      if (report.hasLocation)
        OutlinedButton(
          onPressed: () => _openMaps(report),
          child: const Text('Go to the reported spot'),
        ),
      if (inspect)
        FilledButton(
          onPressed: () => _inspect(report),
          child: const Text('Inspect site'),
        ),
      if (report.status == ReportStatus.verifiedValid)
        FilledButton(
          onPressed: () => _submitMaterials(report),
          child: const Text('Update materials and prices'),
        ),
      if (report.status == ReportStatus.taskAssigned ||
          report.status == ReportStatus.workInProgress ||
          report.status == ReportStatus.workCompleted)
        FilledButton(
          onPressed: () => _submitCompletion(report),
          child: const Text('Send completed work photos to official'),
        ),
    ];
  }

  Future<void> _inspect(ReportIssue report) async {
    final draft = await showModalBottomSheet<_InspectionDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => InspectionSheet(publicId: report.publicId),
    );
    if (!mounted || draft == null) return;
    final loc = await LocationService().captureCurrent();
    if (!mounted) return;
    await _run(
      () async {
        await _reports.submitInspection(
          report: report,
          decision: draft.decision,
          reason: draft.reason,
          latitude: loc.latitude,
          longitude: loc.longitude,
          evidenceImages: draft.photos,
          evidenceVideos: draft.videos,
          budgetItems: draft.items,
        );
        if (draft.decision == 'valid' && draft.items.isNotEmpty) {
          await BudgetService().submitBudgetRequest(
            report: report,
            items: draft.items,
            remarks: draft.remarks,
          );
        }
      },
      draft.decision == 'fake'
          ? 'Marked fake. The official can blacklist this public user.'
          : 'Inspection sent. Salary is 15% of the task budget on the Pay tab.',
    );
  }

  Future<void> _submitMaterials(ReportIssue report) async {
    final draft = await showModalBottomSheet<_MaterialsDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => MaterialsSheet(publicId: report.publicId),
    );
    if (!mounted || draft == null || draft.items.isEmpty) return;
    await _run(
      () => _reports.updateInspectionMaterials(
        report: report,
        items: draft.items,
      ),
      'Materials updated. Add payment on the Pay tab if you have not sent it yet.',
    );
  }

  Future<void> _submitCompletion(ReportIssue report) async {
    final draft = await showModalBottomSheet<_CompletionDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => CompletionSheet(publicId: report.publicId),
    );
    if (!mounted || draft == null || draft.photos.isEmpty) return;
    final loc = await LocationService().captureCurrent();
    if (!mounted) return;
    await _run(
      () => _reports.completeReport(
        reportId: report.id,
        proofImages: draft.photos,
        description: draft.description,
        latitude: loc.latitude,
        longitude: loc.longitude,
      ),
      'Completion photos sent to the official.',
    );
  }

  List<Widget> _adminActions(ReportIssue report) {
    return [
      const Text(
        'Worker salary is 15% of the approved task budget. The public does not see salary.',
      ),
      if (report.approvedBudgetAmount != null)
        Text(
          'Current final budget: NPR ${report.approvedBudgetAmount!.toStringAsFixed(0)}',
        ),
    ];
  }

  List<Widget> _publicActions(ReportIssue report) {
    final actions = <Widget>[];
    if (report.canPublicPostAfter ||
        (report.canPublicPostBudget && report.approvedBudgetAmount != null)) {
      if (report.approvedBudgetAmount != null) {
        actions.addAll([
          Text(
            'Final budget NPR ${report.approvedBudgetAmount!.toStringAsFixed(0)}.',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
        ]);
      }
      actions.add(
        ReportFeedPostButton(profile: profile, reportId: report.id),
      );
      return actions;
    }
    return [
      Text('Tracking ${report.publicId}. You will be notified at each step.'),
    ];
  }
}

class _InspectionDraft {
  const _InspectionDraft({
    required this.decision,
    required this.reason,
    required this.remarks,
    required this.photos,
    required this.videos,
    required this.items,
  });

  final String decision;
  final String reason;
  final String remarks;
  final List<XFile> photos;
  final List<XFile> videos;
  final List<Map<String, dynamic>> items;
}

class InspectionSheet extends StatefulWidget {
  const InspectionSheet({super.key, required this.publicId});

  final String publicId;

  @override
  State<InspectionSheet> createState() => _InspectionSheetState();
}

class _InspectionSheetState extends State<InspectionSheet> {
  final _notes = TextEditingController();
  final _remarks = TextEditingController(text: 'Materials needed on site');
  final _rows = <_MaterialRow>[];
  final _photos = <XFile>[];
  final _videos = <XFile>[];
  String _decision = 'valid';

  @override
  void initState() {
    super.initState();
    _rows.add(_newRow());
  }

  _MaterialRow _newRow() => _MaterialRow();

  @override
  void dispose() {
    _notes.dispose();
    _remarks.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _items() {
    final items = <Map<String, dynamic>>[];
    for (final row in _rows) {
      final qty = double.tryParse(row.qty.text) ?? 0;
      final cost = double.tryParse(row.cost.text) ?? 0;
      if (row.name.text.trim().isEmpty || qty <= 0 || cost <= 0) continue;
      items.add({
        'name': row.name.text.trim(),
        'quantity': qty,
        'unit': 'unit',
        'unitCost': cost,
        'labor': 0,
      });
    }
    return items;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final reason = _notes.text.trim();
    if (reason.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write what you found on site.')),
      );
      return;
    }
    final items = _decision == 'valid' ? _items() : <Map<String, dynamic>>[];
    if (_decision == 'valid' && items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least one budget item with quantity and price.',
          ),
        ),
      );
      return;
    }
    final draft = _InspectionDraft(
      decision: _decision,
      reason: reason,
      remarks: _remarks.text.trim().isEmpty
          ? 'Materials for ${widget.publicId}'
          : _remarks.text.trim(),
      photos: List<XFile>.from(_photos),
      videos: List<XFile>.from(_videos),
      items: items,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    Navigator.of(context).pop(draft);
  }

  Future<void> _addPhoto({required bool video}) async {
    final picker = ImagePicker();
    final file = video
        ? await picker.pickVideo(
            source: ImageSource.camera,
            maxDuration: const Duration(seconds: 10),
          )
        : await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (!mounted || file == null) return;
    setState(() {
      if (video) {
        _videos.add(file);
      } else {
        _photos.add(file);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, inset + 16),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.86,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Inspection · ${widget.publicId}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  const Text(
                    '1. On-site verification',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'valid', label: Text('Valid')),
                      ButtonSegment(value: 'fake', label: Text('Fake')),
                    ],
                    selected: {_decision},
                    onSelectionChanged: (value) {
                      setState(() => _decision = value.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'What did you find on site?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _addPhoto(video: false),
                    child: Text(
                      _photos.isEmpty
                          ? 'Add inspection photo'
                          : '${_photos.length} photo(s) added',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _addPhoto(video: true),
                    child: Text(
                      _videos.isEmpty
                          ? 'Add a short video (up to 10 seconds)'
                          : '${_videos.length} video(s) added',
                    ),
                  ),
                  if (_videos.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    for (final clip in _videos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: XFileVideoPreview(
                            file: clip,
                            width: double.infinity,
                            height: 180,
                          ),
                        ),
                      ),
                  ],
                  if (_decision == 'valid') ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      '2. Materials and prices',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    for (final row in _rows)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextField(
                                controller: row.name,
                                decoration: const InputDecoration(
                                  labelText: 'Item',
                                ),
                              ),
                              TextField(
                                controller: row.qty,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Quantity',
                                ),
                              ),
                              TextField(
                                controller: row.cost,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Unit price (NPR)',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _rows.add(_newRow())),
                      child: const Text('Add another item'),
                    ),
                    TextField(
                      controller: _remarks,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Remarks for official / admin',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submit,
              child: const Text('Submit inspection'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialsDraft {
  const _MaterialsDraft({required this.items, required this.remarks});

  final List<Map<String, dynamic>> items;
  final String remarks;
}

class MaterialsSheet extends StatefulWidget {
  const MaterialsSheet({super.key, required this.publicId});

  final String publicId;

  @override
  State<MaterialsSheet> createState() => _MaterialsSheetState();
}

class _MaterialsSheetState extends State<MaterialsSheet> {
  final _remarks = TextEditingController(text: 'Materials needed on site');
  final _rows = <_MaterialRow>[];

  @override
  void initState() {
    super.initState();
    _rows.add(_newRow());
  }

  _MaterialRow _newRow() => _MaterialRow();

  @override
  void dispose() {
    _remarks.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final items = <Map<String, dynamic>>[];
    for (final row in _rows) {
      final qty = double.tryParse(row.qty.text) ?? 0;
      final cost = double.tryParse(row.cost.text) ?? 0;
      if (row.name.text.trim().isEmpty || qty <= 0 || cost <= 0) continue;
      items.add({
        'name': row.name.text.trim(),
        'quantity': qty,
        'unit': 'unit',
        'unitCost': cost,
        'labor': 0,
      });
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one priced item.')),
      );
      return;
    }
    final draft = _MaterialsDraft(
      items: items,
      remarks: _remarks.text.trim().isEmpty
          ? 'Materials for ${widget.publicId}'
          : _remarks.text.trim(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, inset + 16),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Text(
              'Materials · ${widget.publicId}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'List items and prices.',
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final row in _rows)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextField(
                              controller: row.name,
                              decoration: const InputDecoration(
                                labelText: 'Item',
                              ),
                            ),
                            TextField(
                              controller: row.qty,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                              ),
                            ),
                            TextField(
                              controller: row.cost,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Unit price (NPR)',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () => setState(() => _rows.add(_newRow())),
                    child: const Text('Add item'),
                  ),
                  TextField(
                    controller: _remarks,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Remarks for official / admin',
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: _submit,
              child: const Text('Send to official'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionDraft {
  const _CompletionDraft({required this.description, required this.photos});

  final String description;
  final List<XFile> photos;
}

class CompletionSheet extends StatefulWidget {
  const CompletionSheet({super.key, required this.publicId});

  final String publicId;

  @override
  State<CompletionSheet> createState() => _CompletionSheetState();
}

class _CompletionSheetState extends State<CompletionSheet> {
  final _notes = TextEditingController(text: 'Work completed on site');
  final _photos = <XFile>[];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one finished-work photo.')),
      );
      return;
    }
    final draft = _CompletionDraft(
      description: _notes.text.trim(),
      photos: List<XFile>.from(_photos),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, inset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Completion · ${widget.publicId}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          TextField(controller: _notes, maxLines: 2),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final file = await ImagePicker().pickImage(
                source: ImageSource.camera,
                imageQuality: 80,
              );
              if (!mounted || file == null) return;
              setState(() => _photos.add(file));
            },
            child: Text(
              _photos.isEmpty
                  ? 'Add finished-work photo'
                  : '${_photos.length} photo(s)',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submit,
            child: const Text('Send to official'),
          ),
        ],
      ),
    );
  }
}

class _MaterialRow {
  final name = TextEditingController();
  final qty = TextEditingController(text: '1');
  final cost = TextEditingController();

  void dispose() {
    name.dispose();
    qty.dispose();
    cost.dispose();
  }
}

Future<List<UserProfile>?> showAssignWorkersSheet({
  required BuildContext context,
  required List<UserProfile> workers,
  List<String> selectedIds = const [],
  String? reportCategory,
}) async {
  if (workers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No approved workers available yet.')),
    );
    return null;
  }
  final selected = {...selectedIds};
  final lockedIds = {...selectedIds};
  final addingMore = lockedIds.isNotEmpty;
  final category = (reportCategory ?? '').trim();
  final matched = category.isEmpty
      ? workers
      : workers
            .where(
              (worker) => WorkerSpecialties.matchesCategory(
                worker.specializations,
                category,
              ),
            )
            .toList();
  final others = category.isEmpty
      ? const <UserProfile>[]
      : workers
            .where(
              (worker) => !WorkerSpecialties.matchesCategory(
                worker.specializations,
                category,
              ),
            )
            .toList();
  final needed = category.isEmpty
      ? const <String>{}
      : WorkerSpecialties.forReportCategory(category);
  return showModalBottomSheet<List<UserProfile>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: StatefulBuilder(
          builder: (context, setSheet) {
            Widget workerTile(UserProfile person) {
              final locked = lockedIds.contains(person.uid);
              return CheckboxListTile(
                value: selected.contains(person.uid),
                title: Text(person.displayName),
                subtitle: [
                  if (locked) 'Already on this task',
                  if (person.specialtyLabel.isNotEmpty) person.specialtyLabel,
                  if ((person.municipality ?? '').isNotEmpty)
                    person.municipality!,
                ].isEmpty
                    ? null
                    : Text(
                        [
                          if (locked) 'Already on this task',
                          if (person.specialtyLabel.isNotEmpty)
                            person.specialtyLabel,
                          if ((person.municipality ?? '').isNotEmpty)
                            person.municipality!,
                        ].join(' · '),
                      ),
                onChanged: locked
                    ? null
                    : (value) {
                        setSheet(() {
                          if (value == true) {
                            selected.add(person.uid);
                          } else {
                            selected.remove(person.uid);
                          }
                        });
                      },
              );
            }

            Widget heading(String text) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                child: Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              );
            }

            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    addingMore ? 'Add more workers' : 'Assign workers',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    addingMore
                        ? 'Already assigned workers stay on this job. Tick extra workers if they need help.'
                        : category.isEmpty
                        ? 'Select every worker this task needs. A 5-person job can have 5 workers.'
                        : 'Public report: $category. Matching specialties are listed first so you can assign the right crew.',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                  if (needed.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Needed: ${needed.join(', ')}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        if (category.isNotEmpty && matched.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'No approved worker has this specialty yet. Other workers are listed below.',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (category.isNotEmpty && matched.isNotEmpty)
                          heading('Matched for this category'),
                        for (final person in matched) workerTile(person),
                        if (others.isNotEmpty) ...[
                          heading('Other workers'),
                          for (final person in others) workerTile(person),
                        ],
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed:
                        (addingMore
                            ? selected.difference(lockedIds).isEmpty
                            : selected.isEmpty)
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                              workers
                                  .where(
                                    (person) => selected.contains(person.uid),
                                  )
                                  .toList(),
                            );
                          },
                    child: Text(
                      addingMore
                          ? 'Add ${selected.difference(lockedIds).length} extra worker(s)'
                          : 'Assign ${selected.length} worker(s)',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _ReporterPrivacyCard extends StatefulWidget {
  const _ReporterPrivacyCard({required this.report, required this.profile});

  final ReportIssue report;
  final UserProfile profile;

  @override
  State<_ReporterPrivacyCard> createState() => _ReporterPrivacyCardState();
}

class _ReporterPrivacyCardState extends State<_ReporterPrivacyCard> {
  late final Future<ReporterIdentity?> _identity;

  @override
  void initState() {
    super.initState();
    _identity = widget.profile.hasRole(UserRole.admin)
        ? _loadIdentity()
        : Future<ReporterIdentity?>.value(null);
  }

  ReportIssue get report => widget.report;
  UserProfile get profile => widget.profile;

  @override
  Widget build(BuildContext context) {
    if (profile.hasRole(UserRole.public) && report.uid == profile.uid) {
      if (!report.isAnonymous) return const SizedBox.shrink();
      return const _InfoBanner(
        title: 'You submitted this anonymously',
        body:
            'Ward officials cannot see your name. Admin can review it if fraud is suspected.',
      );
    }
    if (report.hidesReporterFrom(profile)) {
      return const _InfoBanner(
        title: 'Anonymous public report',
        body:
            'Reporter identity is hidden from this desk. Admin can open the same report to review it for fraud.',
      );
    }
    if (profile.hasRole(UserRole.admin)) {
      return FutureBuilder<ReporterIdentity?>(
        future: _identity,
        builder: (context, snapshot) {
          final identity = snapshot.data;
          return Card(
            elevation: 0,
            color: const Color(0xFFFFF8E1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.isAnonymous
                        ? 'Reporter identity (admin only)'
                        : 'Reporter',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  if (report.isAnonymous)
                    const Text(
                      'Hidden from officials. Shown here for security and fraud review.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    )
                  else ...[
                    const SizedBox(height: 8),
                    Text(identity?.name.isNotEmpty == true
                        ? identity!.name
                        : (report.citizenName?.isNotEmpty == true
                              ? report.citizenName!
                              : 'Name not on file')),
                    if ((identity?.email ?? '').isNotEmpty)
                      Text(identity!.email),
                    if ((identity?.phone ?? '').isNotEmpty)
                      Text(identity!.phone),
                    if ((identity?.citizenshipNumber ?? '').isNotEmpty)
                      Text('Citizenship: ${identity!.citizenshipNumber}'),
                  ],
                ],
              ),
            ),
          );
        },
      );
    }
    if (!report.isAnonymous && (report.citizenName ?? '').trim().isNotEmpty) {
      return Text(
        'Reported by ${report.citizenName}',
        style: const TextStyle(color: Colors.black54),
      );
    }
    return const SizedBox.shrink();
  }

  Future<ReporterIdentity?> _loadIdentity() async {
    if (report.isAnonymous) {
      return ReportService().fetchReporterIdentity(report);
    }
    final user = await AuthServices().fetchProfile(report.uid);
    if (user == null) {
      return ReporterIdentity(
        uid: report.uid,
        name: report.citizenName ?? '',
        email: '',
        phone: '',
      );
    }
    return ReporterIdentity(
      uid: user.uid,
      name: user.name,
      email: user.email,
      phone: user.phone,
      citizenshipNumber: user.citizenshipNumber,
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFEEEEEE),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
