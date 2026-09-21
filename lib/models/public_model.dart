import 'package:cloud_firestore/cloud_firestore.dart';

class UserRole {
  static const String public = 'public';
  static const String official = 'official';
  static const String worker = 'worker';
  static const String admin = 'admin';

  static const List<String> all = [public, official, worker, admin];

  static String? normalize(String? raw) {
    if (raw == null) return null;
    switch (raw.trim().toLowerCase()) {
      case 'public':
      case 'citizen':
        return public;
      case 'official':
        return official;
      case 'worker':
        return worker;
      case 'admin':
        return admin;
      default:
        return raw.trim().isEmpty ? null : raw.trim().toLowerCase();
    }
  }

  static bool isKnown(String? role) => all.contains(normalize(role));
}

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? role;
  final String? employeeId;
  final String? approvalStatus;
  final String? accountStatus;
  final String? profileImageUrl;
  final String? specialization;
  final DateTime? createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.role,
    this.employeeId,
    this.approvalStatus,
    this.accountStatus,
    this.profileImageUrl,
    this.specialization,
    this.createdAt,
  });

  String? get normalizedRole => UserRole.normalize(role);

  String get status {
    final value = accountStatus ?? approvalStatus;
    if (value == null || value.isEmpty) return 'approved';
    return value;
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserProfile.fromMap(doc.id, data);
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return UserProfile(
      uid: (data['uid'] as String?) ?? uid,
      name: (data['name'] as String?) ?? (data['fullName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      role: data['role'] as String?,
      employeeId: data['employeeId'] as String?,
      approvalStatus: data['approvalStatus'] as String?,
      accountStatus: data['accountStatus'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      specialization: data['specialization'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

class ReportIssue {
  final String id;
  final String uid;
  final String title;
  final String description;
  final String category;
  final String status;
  final String? assignedWorkerId;
  final String? assignedWorkerName;
  final String? imageUrl;
  final String? videoUrl;
  final String? proofImageUrl;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime? createdAt;

  const ReportIssue({
    required this.id,
    required this.uid,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.assignedWorkerId,
    this.assignedWorkerName,
    this.imageUrl,
    this.videoUrl,
    this.proofImageUrl,
    this.latitude,
    this.longitude,
    this.address,
    this.createdAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory ReportIssue.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return ReportIssue(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      category: (data['category'] as String?) ?? 'General',
      status: (data['status'] as String?) ?? 'submitted',
      assignedWorkerId: data['assignedWorkerId'] as String?,
      assignedWorkerName: data['assignedWorkerName'] as String?,
      imageUrl: data['imageUrl'] as String?,
      videoUrl: data['videoUrl'] as String?,
      proofImageUrl: data['proofImageUrl'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      address: data['address'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

class AccessRequest {
  final String id;
  final String uid;
  final String name;
  final String email;
  final String employeeId;
  final String status;
  final String? phone;
  final String? profileImageUrl;
  final DateTime? createdAt;

  const AccessRequest({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.status,
    this.phone,
    this.profileImageUrl,
    this.createdAt,
  });

  factory AccessRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return AccessRequest(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      employeeId: (data['employeeId'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'pending',
      phone: data['phone'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

class WorkerApplication {
  final String id;
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String status;
  final String? specialization;
  final String? district;
  final String? municipality;
  final String? experienceYears;
  final String? citizenshipNumber;
  final String? profileImageUrl;
  final String? citizenshipFrontUrl;
  final String? citizenshipBackUrl;
  final DateTime? createdAt;

  const WorkerApplication({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    this.specialization,
    this.district,
    this.municipality,
    this.experienceYears,
    this.citizenshipNumber,
    this.profileImageUrl,
    this.citizenshipFrontUrl,
    this.citizenshipBackUrl,
    this.createdAt,
  });

  factory WorkerApplication.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return WorkerApplication(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'pending',
      specialization: data['specialization'] as String?,
      district: data['district'] as String?,
      municipality: data['municipality'] as String?,
      experienceYears: data['experienceYears']?.toString(),
      citizenshipNumber: data['citizenshipNumber'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      citizenshipFrontUrl: data['citizenshipFrontUrl'] as String?,
      citizenshipBackUrl: data['citizenshipBackUrl'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

class AppNotification {
  final String id;
  final String recipientUid;
  final String title;
  final String body;
  final String type;
  final String? relatedId;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.recipientUid,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return AppNotification(
      id: doc.id,
      recipientUid: (data['recipientUid'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'general',
      relatedId: data['relatedId'] as String?,
      read: data['read'] == true,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

class FeedPost {
  final String id;
  final String uid;
  final String authorName;
  final String text;
  final String? imageUrl;
  final DateTime? createdAt;

  const FeedPost({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.text,
    this.imageUrl,
    this.createdAt,
  });

  factory FeedPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return FeedPost(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      imageUrl: data['imageUrl'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

class BudgetItem {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String notes;
  final String createdBy;
  final DateTime? createdAt;

  const BudgetItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.notes,
    required this.createdBy,
    this.createdAt,
  });

  factory BudgetItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return BudgetItem(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      category: (data['category'] as String?) ?? 'General',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      notes: (data['notes'] as String?) ?? '',
      createdBy: (data['createdBy'] as String?) ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}
