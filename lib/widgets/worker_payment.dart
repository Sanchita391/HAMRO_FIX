import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WorkerPay {
  static const double maxPercent = 0.15;

  static double itemsTotal(List<Map<String, dynamic>> items) {
    var total = 0.0;
    for (final item in items) {
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
      final unit = (item['unitCost'] as num?)?.toDouble() ?? 0;
      total += qty * unit;
    }
    return total;
  }

  static double cap(double itemsTotal) => itemsTotal * maxPercent;

  /// Worker salary is 15% of the admin / materials budget (e.g. NPR 500 → NPR 75).
  static double salaryOf(double budget) {
    if (budget <= 0) return 0;
    return budget * maxPercent;
  }

  static bool isWithinCap(double payment, double itemsTotal) {
    if (payment < 0) return false;
    return payment <= cap(itemsTotal) + 0.009;
  }
}

class WorkerPaymentFields extends StatelessWidget {
  const WorkerPaymentFields({
    super.key,
    required this.payment,
    required this.days,
    required this.itemsTotal,
  });

  final TextEditingController payment;
  final TextEditingController days;
  final double itemsTotal;

  @override
  Widget build(BuildContext context) {
    final cap = WorkerPay.cap(itemsTotal);
    final asked = double.tryParse(payment.text.trim()) ?? 0;
    final over = asked > 0 && !WorkerPay.isWithinCap(asked, itemsTotal);
    return Card(
      color: const Color(0xFFF1F8E9),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your salary',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              itemsTotal <= 0
                  ? 'Add priced items first. Salary cannot exceed 15% of materials.'
                  : 'Materials NPR ${itemsTotal.toStringAsFixed(0)} (not added to salary). Max salary NPR ${cap.toStringAsFixed(0)} (15%).',
              style: const TextStyle(color: Colors.black54, height: 1.35),
            ),
            TextField(
              controller: payment,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Salary for this task (NPR)',
                errorText: over
                    ? 'Cannot be more than 15% of the listed items'
                    : null,
              ),
            ),
            TextField(
              controller: days,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'How many days will this take?',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkerPaymentSummary extends StatelessWidget {
  const WorkerPaymentSummary({
    super.key,
    required this.itemsTotal,
    required this.expectedPayment,
    required this.expectedDays,
    this.salaryAsGrandTotal = false,
  });

  final double itemsTotal;
  final double expectedPayment;
  final int expectedDays;
  final bool salaryAsGrandTotal;

  @override
  Widget build(BuildContext context) {
    if (itemsTotal <= 0 && expectedPayment <= 0 && expectedDays <= 0) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 0,
      color: const Color(0xFFE8F5E9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              salaryAsGrandTotal ? 'Your salary' : 'Worker salary',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (itemsTotal > 0)
              _row('Task budget', 'NPR ${itemsTotal.toStringAsFixed(0)}'),
            _row(
              'Worker salary (15%)',
              'NPR ${expectedPayment.toStringAsFixed(0)}',
            ),
            if (expectedDays > 0)
              _row('Expected days', '$expectedDays day(s)'),
            const Divider(height: 18),
            _row(
              salaryAsGrandTotal ? 'Total salary' : 'Salary to pay worker',
              'NPR ${expectedPayment.toStringAsFixed(0)}',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black54,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
