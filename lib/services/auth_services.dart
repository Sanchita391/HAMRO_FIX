import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/notification_service.dart';
import 'package:hamro_fix/services/storage_service.dart';

class AuthServices {
  AuthServices({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    StorageService? storage,
    NotificationService? notifications,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? StorageService(),
       _notifications = notifications ?? NotificationService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final StorageService _storage;
  final NotificationService _notifications;

  static const _users = 'users';
  static const _phoneIndex = 'phone_index';
  static const _accessRequests = 'access_requests';
  static const _workerApplications = 'workerApplications';
  static const _officialApplications = 'officialApplications';

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String formatNepaliPhone(String phone) {
    final digits = phone.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (digits.startsWith('+977')) return digits;
    if (digits.startsWith('977') && digits.length >= 12) {
      return '+$digits';
    }
    return '+977$digits';
  }

  Future<void> _ensureAuthToken(User user) async {
    await user.getIdToken(true);
    await user.reload();
  }

  Future<UserCredential> registerCitizen({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    XFile? profileImage,
  }) async {
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'internal-error',
          message: 'Account creation failed.',
        );
      }

      await _ensureAuthToken(user);
      await user.updateDisplayName(fullName.trim());

      String? profileImageUrl;
      if (profileImage != null) {
        profileImageUrl = await _storage.uploadXFile(
          path: 'profile/${user.uid}/avatar.jpg',
          file: profileImage,
        );
      }

      final formattedPhone = formatNepaliPhone(phone);
      await _writeUserProfile(
        uid: user.uid,
        name: fullName.trim(),
        email: email.trim(),
        phone: formattedPhone,
        role: UserRole.public,
        accountStatus: 'approved',
        profileImageUrl: profileImageUrl,
      );
      await _writePhoneIndex(
        phone: formattedPhone,
        email: email.trim(),
        uid: user.uid,
      );
      return credential;
    } catch (e) {
      await _rollbackNewUser(credential);
      rethrow;
    }
  }

  Future<UserCredential> registerWorker({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required Map<String, dynamic> extra,
    XFile? passportPhoto,
    XFile? citizenshipFront,
    XFile? citizenshipBack,
  }) async {
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'internal-error',
          message: 'Account creation failed.',
        );
      }
      await _ensureAuthToken(user);
      await user.updateDisplayName(fullName.trim());
      final formattedPhone = formatNepaliPhone(phone);

      String? profileImageUrl;
      String? frontUrl;
      String? backUrl;
      if (passportPhoto != null) {
        profileImageUrl = await _storage.uploadXFile(
          path: 'applications/workers/${user.uid}/passport.jpg',
          file: passportPhoto,
        );
      }
      if (citizenshipFront != null) {
        frontUrl = await _storage.uploadXFile(
          path: 'applications/workers/${user.uid}/citizenship_front.jpg',
          file: citizenshipFront,
        );
      }
      if (citizenshipBack != null) {
        backUrl = await _storage.uploadXFile(
          path: 'applications/workers/${user.uid}/citizenship_back.jpg',
          file: citizenshipBack,
        );
      }

      await _writeUserProfile(
        uid: user.uid,
        name: fullName.trim(),
        email: email.trim(),
        phone: formattedPhone,
        role: UserRole.worker,
        accountStatus: 'pending',
        profileImageUrl: profileImageUrl,
        extra: {
          'specialization': extra['specialization'],
        }..removeWhere((key, value) => value == null),
      );

      await _firestore.collection(_workerApplications).doc(user.uid).set({
        'uid': user.uid,
        'name': fullName.trim(),
        'email': email.trim(),
        'phone': formattedPhone,
        'status': 'pending',
        'profileImageUrl': profileImageUrl,
        'citizenshipFrontUrl': frontUrl,
        'citizenshipBackUrl': backUrl,
        'createdAt': FieldValue.serverTimestamp(),
        ...extra,
      }..removeWhere((key, value) => value == null));

      await _writePhoneIndex(
        phone: formattedPhone,
        email: email.trim(),
        uid: user.uid,
      );
      return credential;
    } catch (e) {
      await _rollbackNewUser(credential);
      rethrow;
    }
  }

  Future<void> requestOfficialAccess({
    required String fullName,
    required String email,
    required String employeeId,
    required String password,
  }) async {
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'internal-error',
          message: 'Account creation failed.',
        );
      }
      await _ensureAuthToken(user);
      await user.updateDisplayName(fullName.trim());
      await _writeUserProfile(
        uid: user.uid,
        name: fullName.trim(),
        email: email.trim(),
        phone: '',
        role: UserRole.official,
        accountStatus: 'pending',
        extra: {'employeeId': employeeId.trim()},
      );
      final payload = {
        'uid': user.uid,
        'name': fullName.trim(),
        'email': email.trim(),
        'employeeId': employeeId.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection(_accessRequests).doc(user.uid).set(payload);
      await _firestore
          .collection(_officialApplications)
          .doc(user.uid)
          .set(payload);
    } catch (e) {
      await _rollbackNewUser(credential);
      rethrow;
    }
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
    String? expectedRole,
    String? employeeId,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    try {
      await _assertLoginProfile(
        uid: credential.user?.uid,
        expectedRole: expectedRole,
        employeeId: employeeId,
      );
      final uid = credential.user?.uid;
      if (uid != null) {
        await _notifications.saveFcmToken(uid);
      }
      return credential;
    } catch (e) {
      await _auth.signOut();
      rethrow;
    }
  }

  Future<UserCredential> loginCitizen({
    required String email,
    required String password,
  }) {
    return loginWithEmail(
      email: email,
      password: password,
      expectedRole: UserRole.public,
    );
  }

  Future<UserCredential> loginWithPhone({
    required String phone,
    required String password,
    String? expectedRole,
  }) async {
    final formatted = formatNepaliPhone(phone);
    final snapshot = await _firestore
        .collection(_phoneIndex)
        .doc(_phoneDocId(formatted))
        .get();
    final email = snapshot.data()?['email'] as String?;
    if (!snapshot.exists || email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'This account does not exist.',
      );
    }
    return loginWithEmail(
      email: email,
      password: password,
      expectedRole: expectedRole,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    final doc = await _firestore.collection(_users).doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _firestore.collection(_users).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<void> updateOwnProfile({
    required String uid,
    required String name,
    required String phone,
    XFile? profileImage,
  }) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'fullName': name.trim(),
      'phone': formatNepaliPhone(phone),
    };
    if (profileImage != null) {
      data['profileImageUrl'] = await _storage.uploadXFile(
        path: 'profile/$uid/avatar.jpg',
        file: profileImage,
      );
    }
    await _firestore.collection(_users).doc(uid).update(data);
  }

  Stream<List<UserProfile>> watchUsers() {
    return _firestore.collection(_users).snapshots().map((snapshot) {
      return snapshot.docs.map(UserProfile.fromFirestore).toList();
    });
  }

  Future<List<UserProfile>> listUsers() async {
    final snapshot = await _firestore.collection(_users).get();
    return snapshot.docs.map(UserProfile.fromFirestore).toList();
  }

  Stream<List<AccessRequest>> watchOfficialApplications() {
    return _firestore.collection(_officialApplications).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map(AccessRequest.fromFirestore).toList();
    });
  }

  Stream<List<WorkerApplication>> watchWorkerApplications() {
    return _firestore.collection(_workerApplications).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map(WorkerApplication.fromFirestore).toList();
    });
  }

  Future<List<AccessRequest>> listAccessRequests() async {
    final snapshot = await _firestore.collection(_officialApplications).get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.map(AccessRequest.fromFirestore).toList();
    }
    final legacy = await _firestore.collection(_accessRequests).get();
    return legacy.docs.map(AccessRequest.fromFirestore).toList();
  }

  Future<void> approveOfficialRequest(AccessRequest request) async {
    final admin = _auth.currentUser;
    if (admin == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await _firestore.collection(_users).doc(request.uid).set({
      'uid': request.uid,
      'name': request.name,
      'fullName': request.name,
      'email': request.email,
      'phone': request.phone ?? '',
      'role': UserRole.official,
      'employeeId': request.employeeId,
      'accountStatus': 'approved',
      'approvalStatus': 'approved',
      'reviewedBy': admin.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _updateApplicationStatus(
      collection: _officialApplications,
      id: request.id,
      status: 'approved',
      reviewerUid: admin.uid,
    );
    await _firestore.collection(_accessRequests).doc(request.id).set({
      'status': 'approved',
      'reviewedBy': admin.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _notifications.send(
      recipientUid: request.uid,
      title: 'Official access approved',
      body:
          'Your official application for ${request.email} was approved. You can now sign in to the official dashboard.',
      type: 'official_approval',
      relatedId: request.id,
    );
  }

  Future<void> rejectOfficialRequest(AccessRequest request) async {
    final admin = _auth.currentUser;
    await _firestore.collection(_users).doc(request.uid).set({
      'accountStatus': 'rejected',
      'approvalStatus': 'rejected',
    }, SetOptions(merge: true));
    await _updateApplicationStatus(
      collection: _officialApplications,
      id: request.id,
      status: 'rejected',
      reviewerUid: admin?.uid,
    );
    await _firestore.collection(_accessRequests).doc(request.id).set({
      'status': 'rejected',
      'reviewedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _notifications.send(
      recipientUid: request.uid,
      title: 'Official access not approved',
      body: 'Your official application was not approved.',
      type: 'official_rejection',
      relatedId: request.id,
    );
  }

  Future<void> approveWorkerApplication(WorkerApplication application) async {
    final official = _auth.currentUser;
    if (official == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await _firestore.collection(_users).doc(application.uid).set({
      'accountStatus': 'approved',
      'approvalStatus': 'approved',
      'reviewedBy': official.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _updateApplicationStatus(
      collection: _workerApplications,
      id: application.id,
      status: 'approved',
      reviewerUid: official.uid,
    );
    await _notifications.send(
      recipientUid: application.uid,
      title: 'Worker application approved',
      body:
          'Your worker application for ${application.email} has been approved. Sign in to activate your worker dashboard. Use Forgot password if you need to set a new password.',
      type: 'worker_approval',
      relatedId: application.id,
    );
  }

  Future<void> rejectWorkerApplication(WorkerApplication application) async {
    final official = _auth.currentUser;
    await _firestore.collection(_users).doc(application.uid).set({
      'accountStatus': 'rejected',
      'approvalStatus': 'rejected',
    }, SetOptions(merge: true));
    await _updateApplicationStatus(
      collection: _workerApplications,
      id: application.id,
      status: 'rejected',
      reviewerUid: official?.uid,
    );
    await _notifications.send(
      recipientUid: application.uid,
      title: 'Worker application not approved',
      body: 'Your worker application was not approved.',
      type: 'worker_rejection',
      relatedId: application.id,
    );
  }

  Future<void> setUserRole({
    required String uid,
    required String role,
    String approvalStatus = 'approved',
  }) async {
    final normalized = UserRole.normalize(role);
    if (normalized == null || !UserRole.isKnown(normalized)) {
      throw StateError('Invalid role');
    }
    if (normalized == UserRole.admin) {
      throw const AuthFailure('Admin role cannot be assigned from the app.');
    }
    await _firestore.collection(_users).doc(uid).update({
      'role': normalized,
      'approvalStatus': approvalStatus,
      'accountStatus': approvalStatus,
    });
  }

  Future<void> setWorkerApproval({
    required String uid,
    required String approvalStatus,
  }) async {
    await _firestore.collection(_users).doc(uid).update({
      'approvalStatus': approvalStatus,
      'accountStatus': approvalStatus,
    });
  }

  Future<bool> hasPendingOfficialRequest(String uid) async {
    final official = await _firestore
        .collection(_officialApplications)
        .doc(uid)
        .get();
    if (official.exists && official.data()?['status'] == 'pending') {
      return true;
    }
    final doc = await _firestore.collection(_accessRequests).doc(uid).get();
    return doc.exists && (doc.data()?['status'] == 'pending');
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _assertLoginProfile({
    required String? uid,
    String? expectedRole,
    String? employeeId,
  }) async {
    if (uid == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final profile = await fetchProfile(uid);
    if (profile == null) {
      final pending = await hasPendingOfficialRequest(uid);
      if (pending) {
        return;
      }
      throw const AuthFailure(
        'Your account role has not been configured. Please contact the administrator.',
      );
    }
    if (profile.role == null || profile.role!.trim().isEmpty) {
      throw const AuthFailure(
        'Your account role has not been configured. Please contact the administrator.',
      );
    }
    if (!UserRole.isKnown(profile.role)) {
      throw const AuthFailure(
        'Your account role has not been configured. Please contact the administrator.',
      );
    }
    if (expectedRole != null && profile.normalizedRole != expectedRole) {
      throw const AuthFailure(
        'You do not have permission to access this page.',
      );
    }
    if (expectedRole == UserRole.official &&
        employeeId != null &&
        employeeId.trim().isNotEmpty &&
        (profile.employeeId ?? '') != employeeId.trim()) {
      throw const AuthFailure('Invalid email or password.');
    }
    if (profile.status == 'rejected') {
      throw const AuthFailure(
        'This application was not approved. Please contact the administrator.',
      );
    }
  }

  Future<void> _writeUserProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String role,
    required String accountStatus,
    String? profileImageUrl,
    Map<String, dynamic>? extra,
  }) async {
    await _firestore.collection(_users).doc(uid).set({
      'uid': uid,
      'name': name,
      'fullName': name,
      'email': email,
      'phone': phone,
      'role': role,
      'accountStatus': accountStatus,
      'approvalStatus': accountStatus,
      'profileImageUrl': profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      ...?extra,
    });
  }

  Future<void> _writePhoneIndex({
    required String phone,
    required String email,
    required String uid,
  }) async {
    await _firestore.collection(_phoneIndex).doc(_phoneDocId(phone)).set({
      'email': email,
      'uid': uid,
    });
  }

  Future<void> _updateApplicationStatus({
    required String collection,
    required String id,
    required String status,
    String? reviewerUid,
  }) async {
    await _firestore.collection(collection).doc(id).set({
      'status': status,
      'reviewedBy': reviewerUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _phoneDocId(String phone) =>
      phone.replaceAll('+', '').replaceAll(RegExp(r'\s'), '');

  Future<void> _rollbackNewUser(UserCredential? credential) async {
    final user = credential?.user;
    if (user == null) return;
    try {
      await user.delete();
    } catch (_) {
      await _auth.signOut();
    }
  }
}
