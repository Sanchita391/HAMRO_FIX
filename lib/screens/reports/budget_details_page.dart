import 'package:flutter/material.dart';

import 'package:hamro_fix/core/theme/app_theme.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/budget_service.dart';
import 'package:hamro_fix/services/report_service.dart';
import 'package:hamro_fix/widgets/stored_image.dart';
import 'package:hamro_fix/widgets/web_narrow_body.dart';
import 'package:hamro_fix/widgets/worker_payment.dart';

class BudgetDetailsPage extends StatefulWidget {
  const BudgetDetailsPage({
    super.key,
    required this.request,
    this.allowDecide = false,
  });

  final BudgetRequest request;
  final bool allowDecide;

  @override
  State<BudgetDetailsPage> createState() => _BudgetDetailsPageState();
}

class _BudgetDetailsPageState extends State<BudgetDetailsPage> {
  bool _busy = false;

  Future<void> _decide(bool approve, ReportIssue? report) async {
    final itemsTotal = widget.request.itemsSubtotal > 0
        ? widget.request.itemsSubtotal
        : WorkerPay.itemsTotal(widget.request.items);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve budget?' : 'Reject budget?'),
        content: Text(
          approve
              ? 'Task budget NPR ${itemsTotal.toStringAsFixed(0)}. Worker salary will be NPR ${WorkerPay.salaryOf(itemsTotal).toStringAsFixed(0)} (15%). The public will only see the task budget.'
              : 'NPR ${itemsTotal.toStringAsFixed(0)} for ${report?.publicId ?? widget.request.reportId}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await BudgetService().adminDecide(
        request: widget.request,
        approve: approve,
        remarks: approve ? 'Approved by admin' : 'Rejected by admin',
        report: report,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Budget approved.' : 'Budget rejected.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthMessages.from(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> _photos(ReportIssue report) {
    final urls = <String>{
      if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
        report.imageUrl!,
      ...report.imageUrls,
      ...report.workerEvidenceImages,
      ...report.completionImages,
      if (report.proofImageUrl != null && report.proofImageUrl!.isNotEmpty)
        report.proofImageUrl!,
    };
    return urls.toList();
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Scaffold(
      backgroundColor: HamroFixTheme.canvas,
      appBar: AppBar(title: const Text('Budget details')),
      body: WebNarrowBody(
        maxWidth: 720,
        child: request.reportId.isEmpty
            ? _buildBody(null)
            : StreamBuilder(
                stream: ReportService().watchReport(request.reportId),
                builder: (context, snapshot) {
                  final report = snapshot.data?.exists == true
                      ? ReportIssue.fromFirestore(snapshot.data!)
                      : null;
                  return _buildBody(report);
                },
              ),
      ),
    );
  }

  Widget _buildBody(ReportIssue? report) {
    final request = widget.request;
    final photos = report == null ? const <String>[] : _photos(report);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'NPR ${request.estimatedTotal.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
        ),
        const SizedBox(height: 4),
        Text(
          report == null
              ? 'Report ${request.reportId}'
              : '${report.publicId} · ${report.category}',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Chip(label: Text(request.status.replaceAll('_', ' '))),
        if (report != null) ...[
          const SizedBox(height: 16),
          Text(
            report.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(report.description),
          if (report.crewLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Workers: ${report.crewLabel}'),
          ],
        ],
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Report and inspection photos',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: StoredImage(photos[index], width: 160, height: 160),
                );
              },
            ),
          ),
        ],
        if (report != null && report.inspectionItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Inspection budget items',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final line in report.inspectionItems) _LineItem(line: line),
        ],
        const SizedBox(height: 16),
        const Text(
          'Requested materials',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (request.items.isEmpty)
          const Text('No line items were attached.')
        else
          for (final line in request.items) _LineItem(line: line),
        const SizedBox(height: 12),
        WorkerPaymentSummary(
          itemsTotal: request.itemsSubtotal > 0
              ? request.itemsSubtotal
              : WorkerPay.itemsTotal(request.items),
          expectedPayment: WorkerPay.salaryOf(
            request.itemsSubtotal > 0
                ? request.itemsSubtotal
                : WorkerPay.itemsTotal(request.items),
          ),
          expectedDays: request.expectedWorkDays,
        ),
        if (request.remarks.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Remarks', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(request.remarks),
        ],
        if (widget.allowDecide) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _decide(false, report),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : () => _decide(true, report),
                  child: Text(_busy ? 'Working...' : 'Approve budget'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({required this.line});

  final Map<String, dynamic> line;

  @override
  Widget build(BuildContext context) {
    final qty = (line['quantity'] as num?)?.toDouble() ?? 0;
    final cost = (line['unitCost'] as num?)?.toDouble() ?? 0;
    final total = qty * cost;
    return Card(
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        title: Text('${line['name'] ?? 'Item'}'),
        subtitle: Text(
          '${qty.toStringAsFixed(0)} × NPR ${cost.toStringAsFixed(0)}',
        ),
        trailing: Text(
          'NPR ${total.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
