import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:hamro_fix/models/public_model.dart';

class BudgetService {
  BudgetService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _budgets =>
      _firestore.collection('budgets');

  Stream<List<BudgetItem>> watchBudgets() {
    return _budgets.snapshots().map((snapshot) {
      final items = snapshot.docs.map(BudgetItem.fromFirestore).toList();
      items.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      return items;
    });
  }

  Future<void> createBudget({
    required String title,
    required String category,
    required double amount,
    required String notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await _budgets.add({
      'title': title.trim(),
      'category': category,
      'amount': amount,
      'notes': notes.trim(),
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
