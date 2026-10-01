import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hamro_fix/core/utils/secure_password.dart';
import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/services/audit_service.dart';
import 'package:hamro_fix/services/auth_messages.dart';
import 'package:hamro_fix/services/notification_service.dart';
import 'package:hamro_fix/services/storage_service.dart';

// Handles Firebase Auth plus user profiles in Firestore (users, applications).
class AuthServices {
  AuthServices({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    StorageService? storage,
    NotificationService? notifications,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? StorageService(),
       _notifications = notifications ?? NotificationService(),
       _audit = AuditService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final StorageService _storage;
  final NotificationService _notifications;
  final AuditService _audit;

  static const _users = 'users';
  static const _phoneIndex = 'phone_index';
  static const _accessRequests = 'access_requests';
  static const _workerApplications = 'workerApplications';
  static const _officialApplications = 'officialApplications';
  static const _usernameIndex = 'username_index';

  User? get currentUser => _auth.currentUser;
  // Used by AuthGate to know when someone signs in or out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Stream<User?> get userChanges => _auth.userChanges();

  // Store phones as +977... so login-by-phone can look them up.
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
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  // Create a public Auth user and a users/{uid} document, then send a verify email.
  Future<UserCredential> registerCitizen({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    XFile? profileImage,
    Map<String, dynamic>? extra,
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
      await _writeUserProfile(
        uid: user.uid,
        name: fullName.trim(),
        email: email.trim(),
        phone: formattedPhone,
        role: UserRole.public,
        accountStatus: 'approved',
        extra: extra,
      );
      try {
        await _writePhoneIndex(
          phone: formattedPhone,
          email: email.trim(),
          uid: user.uid,
        );
      } catch (_) {}

      if (profileImage != null) {
        try {
          final profileImageUrl = await _storage.encodeImage(
            profileImage,
            maxWidth: 240,
            maxBytes: 80000,
          );
          if (profileImageUrl != null) {
            await _firestore.collection(_users).doc(user.uid).set({
              'profileImageUrl': profileImageUrl,
            }, SetOptions(merge: true));
          }
        } catch (_) {}
      }

      try {
        await user.sendEmailVerification();
      } catch (_) {}
      try {
        await _audit.log(
          action: 'citizen_registered',
          targetType: 'user',
          targetId: user.uid,
          actorRole: UserRole.public,
        );
      } catch (_) {}
      return credential;
    } catch (e) {
      await _rollbackNewUser(credential);
      rethrow;
    }
  }

  // Create a worker Auth account as pending, save the application, then sign out.
  Future<void> registerWorker({
    required String fullName,
    required String email,
    required String phone,
    String? password,
    required Map<String, dynamic> extra,
    XFile? passportPhoto,
    XFile? citizenshipFront,
    XFile? citizenshipBack,
  }) async {
    final existing = _auth.currentUser;
    if (existing != null) {
      throw const AuthFailure(
        'Each email can be used for only one role. Sign out, then register the worker with a new email.',
      );
    }

    UserCredential? credential;
    try {
      final generated = (password == null || password.isEmpty)
          ? SecurePassword.generate()
          : password;
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: generated,
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
      await _submitWorkerApplication(
        uid: user.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        extra: extra,
        passportPhoto: passportPhoto,
        citizenshipFront: citizenshipFront,
        citizenshipBack: citizenshipBack,
        generatedPassword: generated,
        createProfile: true,
        signOutAfter: true,
      );
    } catch (e) {
      await _rollbackNewUser(credential);
      rethrow;
    }
  }

  // Save worker photos and the workerApplications document for official review.
  Future<void> _submitWorkerApplication({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
    required Map<String, dynamic> extra,
    required XFile? passportPhoto,
    required XFile? citizenshipFront,
    required XFile? citizenshipBack,
    required String? generatedPassword,
    required bool createProfile,
    required bool signOutAfter,
  }) async {
    final existingApp = await _firestore
        .collection(_workerApplications)
        .doc(uid)
        .get();
    if (existingApp.exists && existingApp.data()?['status'] == 'pending') {
      throw const AuthFailure(
        'A worker application for this account is already waiting for review.',
      );
    }
    if (existingApp.exists && existingApp.data()?['status'] == 'approved') {
      throw const AuthFailure('This account already has worker access.');
    }

    final formattedPhone = formatNepaliPhone(phone);
    String? profileImageUrl;
    String? frontUrl;
    String? backUrl;
    if (passportPhoto != null) {
      profileImageUrl = await _storage.encodeImage(
        passportPhoto,
        maxWidth: 240,
        maxBytes: 80000,
      );
    }
    if (citizenshipFront != null) {
      frontUrl = await _storage.encodeImage(
        citizenshipFront,
        maxWidth: 200,
        maxBytes: 80000,
      );
    }
    if (citizenshipBack != null) {
      backUrl = await _storage.encodeImage(
        citizenshipBack,
        maxWidth: 200,
        maxBytes: 80000,
      );
    }

    if (createProfile) {
      await _writeUserProfile(
        uid: uid,
        name: fullName.trim(),
        email: email.trim(),
        phone: formattedPhone,
        role: UserRole.worker,
        accountStatus: 'pending',
        profileImageUrl: profileImageUrl,
        extra: {
          'specialization': extra['specialization'],
          'specializations': extra['specializations'],
          'district': extra['district'],
          'municipality': extra['municipality'],
          'mustChangePassword': true,
        }..removeWhere((key, value) => value == null),
      );
    } else {
      await _firestore
          .collection(_users)
          .doc(uid)
          .set(
            {
              'specialization': extra['specialization'],
              'specializations': extra['specializations'],
              'district': extra['district'],
              'municipality': extra['municipality'],
              if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            }..removeWhere((key, value) => value == null),
            SetOptions(merge: true),
          );
    }

    await _firestore
        .collection(_workerApplications)
        .doc(uid)
        .set(
          {
            'uid': uid,
            'name': fullName.trim(),
            'email': email.trim(),
            'phone': formattedPhone,
            'status': 'pending',
            'profileImageUrl': profileImageUrl,
            'citizenshipFrontUrl': frontUrl,
            'citizenshipBackUrl': backUrl,
            if (generatedPassword != null)
              'temporaryPassword': generatedPassword,
            'createdAt': FieldValue.serverTimestamp(),
            ...extra,
          }..removeWhere((key, value) => value == null),
        );

    await _writePhoneIndex(
      phone: formattedPhone,
      email: email.trim(),
      uid: uid,
    );
    await _audit.log(
      action: 'worker_application_submitted',
      targetType: 'workerApplication',
      targetId: uid,
      actorRole: UserRole.worker,
    );
    if (signOutAfter) {
      await _auth.signOut();
    }
  }

  // Create a pending official account and application. Admin must approve later.
  Future<void> requestOfficialAccess({
    required String fullName,
    required String email,
    required String employeeId,
    String? password,
    String? phone,
    String? department,
    String? municipality,
    XFile? profileImage,
  }) async {
    UserCredential? credential;
    try {
      final loginPassword = (password == null || password.isEmpty)
          ? SecurePassword.generate()
          : password;
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: loginPassword,
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
        profileImageUrl = await _storage.encodeImage(
          profileImage,
          maxWidth: 240,
          maxBytes: 80000,
        );
      }
      await _writeUserProfile(
        uid: user.uid,
        name: fullName.trim(),
        email: email.trim(),
        phone: (phone == null || phone.trim().isEmpty)
            ? ''
            : formatNepaliPhone(phone),
        role: UserRole.official,
        accountStatus: 'pending',
        profileImageUrl: profileImageUrl,
        extra: {
          'employeeId': employeeId.trim(),
          'department': department,
          'municipality': municipality,
          'mustChangePassword': true,
        }..removeWhere((key, value) => value == null),
      );
      final payload = {
        'uid': user.uid,
        'name': fullName.trim(),
        'email': email.trim(),
        'phone': (phone == null || phone.trim().isEmpty)
            ? null
            : formatNepaliPhone(phone),
        'employeeId': employeeId.trim(),
        'department': department,
        'municipality': municipality,
        'profileImageUrl': profileImageUrl,
        'status': 'pending',
        'temporaryPassword': loginPassword,
        'createdAt': FieldValue.serverTimestamp(),
      }..removeWhere((key, value) => value == null);
      await _firestore.collection(_accessRequests).doc(user.uid).set(payload);
      await _firestore
          .collection(_officialApplications)
          .doc(user.uid)
          .set(payload);
      await _audit.log(
        action: 'official_application_submitted',
        targetType: 'officialApplication',
        targetId: user.uid,
        actorRole: UserRole.official,
      );
      await _auth.signOut();
    } catch (e) {
      await _rollbackNewUser(credential);
      rethrow;
    }
  }

  // Sign in with email/password, then check the Firestore role matches this page.
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
    String? expectedRole,
    String? employeeId,
  }) async {
    try {
      await _firestore.enableNetwork();
    } catch (_) {}
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    // On web the Auth token is sometimes not ready for Firestore yet.
    try {
      await _ensureAuthToken(user);
    } catch (_) {}
    try {
      await _assertLoginProfile(
        uid: user.uid,
        expectedRole: expectedRole,
        employeeId: employeeId,
      );
      try {
        await _notifications.saveFcmToken(user.uid);
      } catch (_) {}
      if (expectedRole == UserRole.admin) {
        await _ensureAdminUsernameIndex(user.uid);
      }
      return credential;
    } catch (e) {
      await _auth.signOut();
      rethrow;
    }
  }

  // Public sign-in page: same as loginWithEmail, but the role must be public.
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

  // Admin can type username or email. Username is looked up in username_index.
  Future<UserCredential> loginAdmin({
    required String identifier,
    required String password,
  }) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) {
      throw const AuthFailure('Enter your admin email or username.');
    }
    final email = trimmed.contains('@')
        ? trimmed
        : await _resolveAdminEmail(trimmed);
    return loginWithEmail(
      email: email,
      password: password,
      expectedRole: UserRole.admin,
    );
  }

  // Web management portal: Firebase email/password, then Official or Admin only.
  Future<UserCredential> loginStaffWeb({
    required String identifier,
    required String password,
    required String expectedRole,
    bool rememberMe = true,
  }) async {
    // Keep the session in this browser tab only when Remember me is off.
    if (kIsWeb) {
      await _auth.setPersistence(
        rememberMe ? Persistence.LOCAL : Persistence.SESSION,
      );
    }

    final trimmed = identifier.trim();
    final email = trimmed.contains('@')
        ? trimmed
        : (expectedRole == UserRole.admin
              ? await _resolveAdminEmail(trimmed)
              : trimmed);

    // Sign in the user using Firebase Authentication.
    final credential = await loginWithEmail(
      email: email,
      password: password,
      expectedRole: expectedRole,
    );

    // Check the user's role matches Official or Admin on this website.
    final uid = credential.user?.uid;
    final profile = uid == null ? null : await fetchProfile(uid);
    final role = UserRole.normalize(profile?.role);
    if (role == UserRole.official || role == UserRole.admin) {
      if (role == UserRole.admin && uid != null) {
        await _ensureAdminUsernameIndex(uid);
      }
      return credential;
    }
    if (uid != null && profile == null) {
      final pending = await hasPendingOfficialRequest(uid);
      if (pending && expectedRole == UserRole.official) return credential;
    }

    await _auth.signOut();
    throw const AuthFailure(
      'This platform is restricted to authorised Official and Admin users. Public and field workers must use the HamroFix phone app.',
    );
  }

  Future<String> _resolveAdminEmail(String username) async {
    final key = username.trim().toLowerCase();
    final snapshot = await _firestore.collection(_usernameIndex).doc(key).get();
    final email = snapshot.data()?['email'] as String?;
    if (email != null && email.isNotEmpty) return email;
    throw const AuthFailure(
      'This admin username is not registered. Sign in with the admin email from Firebase Authentication, then set a username in Profile.',
    );
  }

  Future<void> _ensureAdminUsernameIndex(String uid) async {
    try {
      final profile = await fetchProfile(uid);
      final username = (profile?.username ?? '').trim().toLowerCase();
      final email = profile?.email ?? _auth.currentUser?.email;
      if (username.isEmpty || email == null || email.isEmpty) return;
      await _firestore.collection(_usernameIndex).doc(username).set({
        'email': email,
        'uid': uid,
      });
    } catch (_) {}
  }

  // Save the admin username so they can sign in without typing the full email.
  Future<void> saveAdminUsername(String username) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final key = username.trim().toLowerCase();
    if (key.isEmpty || key.contains(' ')) {
      throw const AuthFailure('Enter a username without spaces.');
    }
    await _firestore.collection(_users).doc(user.uid).set({
      'username': key,
    }, SetOptions(merge: true));
    await _firestore.collection(_usernameIndex).doc(key).set({
      'email': user.email,
      'uid': user.uid,
    });
  }

  // Look up the Auth email from phone_index, then sign in as usual.
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

  // Firebase Auth sends a reset link to this email.
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Read one user document from Firestore.
  Future<UserProfile?> fetchProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_users).doc(uid).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied' && e.code != 'unauthenticated') {
        rethrow;
      }
      // Token may not be attached yet (common in Chrome). Wait, then read once more.
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _ensureAuthToken(user);
        } catch (_) {}
      }
      final retry = await _firestore.collection(_users).doc(uid).get();
      if (!retry.exists) return null;
      return UserProfile.fromFirestore(retry);
    }
  }

  // Live updates of the same user document (used after login).
  Stream<UserProfile?> watchProfile(String uid) {
    return _firestore.collection(_users).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  // Update name, phone, and optional profile photo on the current user.
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
      final encoded = await _storage.encodeImage(
        profileImage,
        maxWidth: 240,
        maxBytes: 80000,
      );
      if (encoded != null) data['profileImageUrl'] = encoded;
    }
    await _firestore.collection(_users).doc(uid).update(data);
  }

  // Admin/official lists of every user document.
  Stream<List<UserProfile>> watchUsers() {
    return _firestore.collection(_users).snapshots().map((snapshot) {
      return snapshot.docs.map(UserProfile.fromFirestore).toList();
    });
  }

  Future<List<UserProfile>> listUsers() async {
    final snapshot = await _firestore.collection(_users).get();
    return snapshot.docs.map(UserProfile.fromFirestore).toList();
  }

  // Live list of official applications for the admin dashboard.
  Stream<List<AccessRequest>> watchOfficialApplications() {
    return _firestore.collection(_officialApplications).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map(AccessRequest.fromFirestore).toList();
    });
  }

  // Live list of worker applications for the official dashboard.
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

  // Admin allows this person to sign in as an official.
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
      'roles': [UserRole.official],
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
          'Your HamroFix official account was approved. Check email for your sign-in details, then open Official Sign In.',
      type: 'official_approval',
      relatedId: request.id,
    );
    await _audit.log(
      action: 'official_approved',
      targetType: 'user',
      targetId: request.uid,
      actorRole: UserRole.admin,
    );
  }

  // Admin rejects the official application.
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

  // Official approves a worker so they can open the worker dashboard.
  Future<void> approveWorkerApplication(WorkerApplication application) async {
    final official = _auth.currentUser;
    if (official == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await _firestore.collection(_users).doc(application.uid).set({
      'accountStatus': 'approved',
      'approvalStatus': 'approved',
      'role': UserRole.worker,
      'roles': [UserRole.worker],
      'reviewedBy': official.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
      if (application.specializations.isNotEmpty)
        'specializations': application.specializations,
      if (application.specialtyLabel.isNotEmpty)
        'specialization': application.specialtyLabel,
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
          'Your HamroFix worker account was approved. Check email for your sign-in details, then open Worker Sign In.',
      type: 'worker_approval',
      relatedId: application.id,
    );
    await _audit.log(
      action: 'worker_approved',
      targetType: 'user',
      targetId: application.uid,
      actorRole: UserRole.official,
    );
  }

  // Official rejects a worker application.
  Future<void> rejectWorkerApplication(WorkerApplication application) async {
    final official = _auth.currentUser;
    final profile = await fetchProfile(application.uid);
    final keepAccount =
        profile != null &&
        (profile.hasRole(UserRole.official) ||
            profile.hasRole(UserRole.public) ||
            profile.hasRole(UserRole.admin));
    await _firestore.collection(_users).doc(application.uid).set({
      if (!keepAccount) ...{
        'accountStatus': 'rejected',
        'approvalStatus': 'rejected',
      },
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

  // Block a worker account and record the reason.
  Future<void> blacklistWorker({
    required WorkerApplication application,
    required String reason,
  }) async {
    final official = _auth.currentUser;
    if (official == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final trimmed = reason.trim();
    if (trimmed.length < 8) {
      throw const AuthFailure('Enter a clear reason (at least 8 characters).');
    }
    await _firestore.collection(_users).doc(application.uid).set({
      'accountStatus': 'blacklisted',
      'approvalStatus': 'blacklisted',
      'status': 'blacklisted',
      'blacklistReason': trimmed,
      'blacklistStatus': 'active',
      'reviewedBy': official.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _firestore.collection('blacklistedUsers').doc(application.uid).set({
      'workerId': application.uid,
      'name': application.name,
      'email': application.email,
      'role': UserRole.worker,
      'reason': trimmed,
      'blacklistedBy': official.uid,
      'blacklistedAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });
    await _updateApplicationStatus(
      collection: _workerApplications,
      id: application.id,
      status: 'blacklisted',
      reviewerUid: official.uid,
    );
    await _notifications.send(
      recipientUid: application.uid,
      title: 'Worker account blacklisted',
      body: 'Your worker account was blacklisted. Reason: $trimmed',
      type: 'blacklist',
      relatedId: application.id,
    );
    await _audit.log(
      action: 'worker_blacklisted',
      targetType: 'user',
      targetId: application.uid,
      actorRole: UserRole.official,
      metadata: {'reason': trimmed},
    );
  }

  // Disable the worker profile (does not delete Firebase Auth by itself).
  Future<void> deleteWorkerProfile({
    required WorkerApplication application,
    required String reason,
  }) async {
    final official = _auth.currentUser;
    if (official == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final trimmed = reason.trim();
    if (trimmed.length < 8) {
      throw const AuthFailure('Enter a clear reason (at least 8 characters).');
    }
    await _firestore.collection(_users).doc(application.uid).set({
      'accountStatus': 'disabled',
      'approvalStatus': 'disabled',
      'status': 'removed',
      'removedReason': trimmed,
      'removedAt': FieldValue.serverTimestamp(),
      'reviewedBy': official.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _firestore
        .collection(_workerApplications)
        .doc(application.id)
        .delete();
    await _notifications.send(
      recipientUid: application.uid,
      title: 'Worker profile removed',
      body: 'Your worker profile was removed. Reason: $trimmed',
      type: 'worker_removed',
      relatedId: application.id,
    );
    await _audit.log(
      action: 'worker_profile_deleted',
      targetType: 'user',
      targetId: application.uid,
      actorRole: UserRole.official,
      metadata: {'reason': trimmed},
    );
  }

  // Change a user's role in Firestore. Admin cannot be assigned from the app.
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

  // True if this uid still has a pending official application.
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

  // Sign out of Firebase Auth. AuthGate then shows the landing page.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send a password-setup email so the new official/worker can sign in.
  Future<void> sendStaffLoginEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendOfficialLoginEmail(String email) =>
      sendStaffLoginEmail(email);

  String staffWelcomeMessage({
    required String name,
    required String email,
    required String roleLabel,
    String? temporaryPassword,
    String? extraLine,
  }) {
    final password = (temporaryPassword ?? '').trim();
    final buffer = StringBuffer()
      ..writeln('Hello $name,')
      ..writeln()
      ..writeln('Your HamroFix $roleLabel account has been approved.')
      ..writeln('Sign in email: $email');
    if (extraLine != null && extraLine.trim().isNotEmpty) {
      buffer.writeln(extraLine.trim());
    }
    if (password.isNotEmpty) {
      buffer
        ..writeln('Temporary password: $password')
        ..writeln()
        ..writeln(
          'Use this email and password on the $roleLabel sign-in page. Change the password after you sign in.',
        );
    } else {
      buffer
        ..writeln()
        ..writeln(
          'Open the HamroFix password email, set a new password, then sign in as a $roleLabel.',
        );
    }
    buffer
      ..writeln()
      ..writeln('HamroFix');
    return buffer.toString();
  }

  String officialWelcomeMessage(AccessRequest request) {
    return staffWelcomeMessage(
      name: request.name,
      email: request.email,
      roleLabel: 'official',
      temporaryPassword: request.temporaryPassword,
      extraLine: request.employeeId.isEmpty
          ? null
          : 'Employee ID (optional): ${request.employeeId}',
    );
  }

  // After Auth login, check the users document: role, rejected, blacklisted.
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
    if (expectedRole != null &&
        UserRole.normalize(profile.role) != UserRole.normalize(expectedRole)) {
      throw const AuthFailure(
        'This email is registered for a different role. Use that role\'s sign-in page, or a different email.',
      );
    }
    if (profile.status == 'rejected') {
      throw const AuthFailure(
        'This application was not approved. Please contact the administrator.',
      );
    }
    if (profile.status == 'blacklisted') {
      throw const AuthFailure(
        'This account is blacklisted. Please contact the administrator.',
      );
    }
    if (profile.status == 'suspended' ||
        profile.status == 'disabled' ||
        profile.status == 'removed') {
      throw const AuthFailure(
        'This account is currently restricted. Please contact the administrator.',
      );
    }
  }

  // Create or overwrite the users/{uid} profile document.
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
    final payload = {
      'uid': uid,
      'name': name,
      'fullName': name,
      'email': email,
      'phone': phone,
      'role': role,
      'roles': [role],
      'accountStatus': accountStatus,
      'approvalStatus': accountStatus,
      'status': accountStatus == 'approved' ? 'active' : accountStatus,
      'profileImageUrl': profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      ...?extra,
    };
    try {
      await _firestore.collection(_users).doc(uid).set(payload);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      await _ensureAuthToken(_auth.currentUser ?? (throw e));
      await _firestore.collection(_users).doc(uid).set(payload);
    }
  }

  // Re-enter the current password, then set a new one in Firebase Auth.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final cred = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
    await _firestore.collection(_users).doc(user.uid).set({
      'mustChangePassword': false,
    }, SetOptions(merge: true));
  }

  // Send another verification email to the signed-in public user.
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.sendEmailVerification();
  }

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
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

  // If registration fails after Auth create, delete that Auth user.
  Future<void> _rollbackNewUser(UserCredential? credential) async {
    final user = credential?.user;
    if (user == null) return;
    try {
      await user.delete();
    } catch (_) {
      await _auth.signOut();
    }
  }

  // True only when no admin has been created yet (appSettings/bootstrap missing).
  Future<bool> isAdminBootstrapOpen() async {
    final doc = await _firestore
        .collection('appSettings')
        .doc('bootstrap')
        .get();
    return !doc.exists;
  }

  // First-time setup: create the only admin account from the app.
  Future<void> bootstrapFirstAdmin({
    required String fullName,
    required String email,
    required String password,
    String username = 'admin',
  }) async {
    if (!await isAdminBootstrapOpen()) {
      throw const AuthFailure(
        'An admin account already exists. Please sign in.',
      );
    }
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
        role: UserRole.admin,
        accountStatus: 'approved',
        extra: {'username': username.trim().toLowerCase()},
      );
      await _firestore.collection('appSettings').doc('bootstrap').set({
        'adminUid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore
          .collection(_usernameIndex)
          .doc(username.trim().toLowerCase())
          .set({'email': email.trim(), 'uid': user.uid});
    } catch (e) {
      await _rollbackNewUser(credential);
      rethrow;
    }
  }
}
