import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hamro_fix/models/public_model.dart';
import 'package:hamro_fix/services/storage_service.dart';

class FeedService {
  FeedService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    StorageService? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? StorageService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StorageService _storage;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('feedPosts');

  Stream<List<FeedPost>> watchPosts() {
    return _posts.snapshots().map((snapshot) {
      final items = snapshot.docs.map(FeedPost.fromFirestore).toList();
      items.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      return items;
    });
  }

  Stream<List<FeedPost>> watchMyPosts(String uid) {
    return _posts.where('uid', isEqualTo: uid).snapshots().map((snapshot) {
      final items = snapshot.docs.map(FeedPost.fromFirestore).toList();
      items.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      return items;
    });
  }

  Future<void> updatePost({required String postId, required String text}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await _posts.doc(postId).update({
      'text': text.trim(),
      'caption': text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await _posts.doc(postId).delete();
  }

  Stream<List<FeedComment>> watchComments(String postId) {
    return _posts.doc(postId).collection('comments').snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(FeedComment.fromFirestore).toList();
      items.sort(
        (a, b) =>
            (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)),
      );
      return items;
    });
  }

  Stream<int> watchCommentCount(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> syncCommentCount(String postId, int count) async {
    try {
      await _posts.doc(postId).update({'commentCount': count});
    } catch (_) {}
  }

  Future<void> createPost({
    required String authorName,
    required String text,
    XFile? image,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    String? imageUrl;
    if (image != null) {
      imageUrl = await _storage.encodeImage(image, maxWidth: 480);
    }
    await _posts.add({
      'uid': user.uid,
      'authorName': authorName,
      'text': text.trim(),
      'imageUrl': imageUrl,
      'likedBy': <String>[],
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleLike(String postId, {required bool liked}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await _posts.doc(postId).update({
      'likedBy': liked
          ? FieldValue.arrayRemove([user.uid])
          : FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> addComment({
    required String postId,
    required String authorName,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _posts.doc(postId).collection('comments').add({
      'uid': user.uid,
      'authorName': authorName.trim().isEmpty ? 'Public' : authorName.trim(),
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
    try {
      await _posts.doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (_) {
      try {
        final comments = await _posts.doc(postId).collection('comments').get();
        await _posts.doc(postId).update({
          'commentCount': comments.docs.length,
        });
      } catch (_) {}
    }
  }
}
