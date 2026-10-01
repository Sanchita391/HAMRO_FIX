import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:hamro_fix/core/constants/app_constants.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/services/auth_messages.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<List<AppNotification>> watchMine(String uid) {
    return _notifications
        .where('recipientUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map(AppNotification.fromFirestore)
              .toList();
          items.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
          return items;
        });
  }

  Future<void> markRead(String id) async {
    await _notifications.doc(id).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllRead(String uid) async {
    final snapshot = await _notifications
        .where('recipientUid', isEqualTo: uid)
        .get();
    final unread = snapshot.docs
        .where((doc) => doc.data()['read'] != true)
        .toList();
    if (unread.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> send({
    required String recipientUid,
    required String title,
    required String body,
    String type = 'general',
    String? relatedId,
    String? senderName,
    String? senderRole,
  }) async {
    final sender = _auth.currentUser;
    var name = senderName?.trim() ?? '';
    var role = senderRole?.trim() ?? '';
    if ((name.isEmpty || role.isEmpty) && sender != null) {
      try {
        final doc = await _users.doc(sender.uid).get();
        final profile = doc.exists
            ? UserProfile.fromFirestore(doc)
            : null;
        if (name.isEmpty) name = profile?.displayName ?? '';
        if (role.isEmpty) role = profile?.staffRole ?? '';
      } catch (_) {}
    }
    await _notifications.add({
      'recipientUid': recipientUid,
      'senderUid': sender?.uid,
      'senderName': name,
      'senderRole': role,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendOrReplace({
    required String recipientUid,
    required String title,
    required String body,
    required String type,
    required String relatedId,
    String? senderName,
    String? senderRole,
  }) async {
    try {
      final snapshot = await _notifications
          .where('recipientUid', isEqualTo: recipientUid)
          .get();
      final hasSame = snapshot.docs.any((doc) {
        final data = doc.data();
        return data['type'] == type && data['relatedId'] == relatedId;
      });
      if (hasSame) return;
    } catch (_) {}
    await send(
      recipientUid: recipientUid,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
      senderName: senderName,
      senderRole: senderRole,
    );
  }

  List<String> composeTargetRoles(String senderRole) {
    switch (senderRole) {
      case UserRole.worker:
        return [UserRole.official];
      case UserRole.official:
        return [UserRole.worker, UserRole.admin];
      case UserRole.admin:
        return [UserRole.official, UserRole.worker];
      default:
        return const [];
    }
  }

  Future<List<UserProfile>> listAlertRecipients(UserProfile sender) async {
    final roles = composeTargetRoles(sender.staffRole);
    final people = <UserProfile>[];
    final seen = <String>{};
    for (final role in roles) {
      try {
        final snapshot = await _users.where('role', isEqualTo: role).get();
        for (final doc in snapshot.docs) {
          if (doc.id == sender.uid || seen.contains(doc.id)) continue;
          final person = UserProfile.fromFirestore(doc);
          if (!person.isApproved) continue;
          seen.add(doc.id);
          people.add(person);
        }
      } catch (_) {}
    }
    people.sort((a, b) => a.displayName.compareTo(b.displayName));
    return people;
  }

  Future<void> sendStaffMessage({
    required UserProfile sender,
    required UserProfile recipient,
    required String message,
  }) async {
    final text = message.trim();
    if (text.length < 8) {
      throw const AuthFailure('Write a clear message (at least 8 characters).');
    }
    final allowed = composeTargetRoles(sender.staffRole);
    if (!allowed.contains(recipient.staffRole) &&
        !allowed.any(recipient.hasRole)) {
      throw const AuthFailure('You cannot send an alert to that account.');
    }
    final from = sender.hasRole(UserRole.admin)
        ? 'admin'
        : sender.hasRole(UserRole.official)
        ? 'official'
        : 'worker';
    await send(
      recipientUid: recipient.uid,
      title: 'Message from $from',
      body: text,
      type: AlertType.message,
      senderName: sender.displayName,
      senderRole: sender.staffRole,
    );
  }

  Future<void> saveFcmToken(String uid) async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FCM token save skipped: $e');
    }
  }
}
