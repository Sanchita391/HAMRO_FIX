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
      _firestore.collection('posts');

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

  Future<void> createPost({
    required String authorName,
    required String text,
    XFile? image,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final doc = _posts.doc();
    String? imageUrl;
    if (image != null) {
      imageUrl = await _storage.uploadXFile(
        path: 'posts/${doc.id}/${image.name}',
        file: image,
      );
    }
    await doc.set({
      'uid': user.uid,
      'authorName': authorName,
      'text': text.trim(),
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
