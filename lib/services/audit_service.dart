import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditService {
  AuditService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> log({
    required String action,
    required String targetType,
    String? targetId,
    String? actorRole,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('auditLogs').add({
      'actorId': user.uid,
      'actorRole': actorRole,
      'action': action,
      'targetId': targetId,
      'targetType': targetType,
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': metadata ?? {},
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchLogs() {
    return _firestore
        .collection('auditLogs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }
}
