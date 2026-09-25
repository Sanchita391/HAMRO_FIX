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
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (report.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: StoredImage(report.imageUrl, height: 200),
                ),
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
                ],
              ),
              if (report.hasLocation) ...[
                const SizedBox(height: 8),
                Text('GPS: ${report.latitude}, ${report.longitude}'),
                TextButton.icon(
                  onPressed: () => _openMaps(report),
                  icon: const Icon(Icons.near_me_rounded),
                  label: const Text('Open this spot on the map'),
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
              if (report.completionImages.isNotEmpty ||
                  report.proofImageUrl != null) ...[
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
                      for (final url in {
                        ...report.completionImages,
                        if (report.proofImageUrl != null) report.proofImageUrl!,
                      })
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: StoredImage(url, width: 90, height: 90),
                        ),
                    ],
                  ),
                ),
              ],
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
      if (report.status == ReportStatus.officialAccepted ||
          report.status == ReportStatus.verifiedValid ||
          report.status == ReportStatus.workerAssigned)
        FilledButton.icon(
          onPressed: () => _assignWorkers(report),
          icon: const Icon(Icons.groups_rounded),
          label: Text(
            report.crewIds.isEmpty
                ? 'Assign workers to inspect'
                : 'Add or change workers (${report.crewIds.length})',
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
            'Approved budget sent to the inspecting worker and the public reporter. They can post it now.',
          ),
          child: const Text('Send approved budget to inspector & public'),
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
    );
    if (selected == null || selected.isEmpty) return;
    await _run(
      () => _reports.assignWorkers(
        reportId: report.id,
        workerIds: selected.map((person) => person.uid).toList(),
        workerNames: selected.map((person) => person.name).toList(),
      ),
      'Assigned ${selected.length} worker(s). The job is on their dashboards.',
    );
  }

  List<Widget> _workerActions(ReportIssue report) {
    final inspect =
        report.status == ReportStatus.workerAssigned ||
        report.status == ReportStatus.workerInspection ||
        report.status == ReportStatus.officialAccepted;
    return [
      if (report.hasLocation)
        OutlinedButton.icon(
          onPressed: () => _openMaps(report),
          icon: const Icon(Icons.map_rounded),
          label: const Text('Go to the reported spot'),
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
    required this.items,
  });

  final String decision;
  final String reason;
  final String remarks;
  final List<XFile> photos;
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
      items: items,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    Navigator.of(context).pop(draft);
  }

  Future<void> _addPhoto({required bool video}) async {
    final picker = ImagePicker();
    final file = video
        ? await picker.pickVideo(source: ImageSource.camera)
        : await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (!mounted || file == null) return;
    setState(() => _photos.add(file));
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
                  OutlinedButton.icon(
                    onPressed: () => _addPhoto(video: false),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(
                      _photos.isEmpty
                          ? 'Add inspection photo'
                          : '${_photos.length} photo(s) added',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _addPhoto(video: true),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Add a short video (if it fits)'),
                  ),
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
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _rows.add(_newRow())),
                      icon: const Icon(Icons.add),
                      label: const Text('Add another item'),
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
                  TextButton.icon(
                    onPressed: () => setState(() => _rows.add(_newRow())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add item'),
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
          OutlinedButton.icon(
            onPressed: () async {
              final file = await ImagePicker().pickImage(
                source: ImageSource.camera,
                imageQuality: 80,
              );
              if (!mounted || file == null) return;
              setState(() => _photos.add(file));
            },
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(
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
}) async {
  if (workers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No approved workers available yet.')),
    );
    return null;
  }
  final selected = {...selectedIds};
  return showModalBottomSheet<List<UserProfile>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: StatefulBuilder(
          builder: (context, setSheet) {
            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Assign workers',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select every worker this task needs. A 5-person job can have 5 workers.',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final person in workers)
                          CheckboxListTile(
                            value: selected.contains(person.uid),
                            title: Text(person.displayName),
                            subtitle: [
                              if ((person.specialization ?? '').isNotEmpty)
                                person.specialization!,
                              if ((person.municipality ?? '').isNotEmpty)
                                person.municipality!,
                            ].isEmpty
                                ? null
                                : Text(
                                    [
                                      if ((person.specialization ?? '')
                                          .isNotEmpty)
                                        person.specialization!,
                                      if ((person.municipality ?? '')
                                          .isNotEmpty)
                                        person.municipality!,
                                    ].join(' · '),
                                  ),
                            onChanged: (value) {
                              setSheet(() {
                                if (value == true) {
                                  selected.add(person.uid);
                                } else {
                                  selected.remove(person.uid);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: selected.isEmpty
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
                    child: Text('Assign ${selected.length} worker(s)'),
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
