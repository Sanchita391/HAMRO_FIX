import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hamro_fix/services/video_prepare_stub.dart'
    if (dart.library.io) 'package:hamro_fix/services/video_prepare_io.dart';

class VideoUploadFailure implements Exception {
  const VideoUploadFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class VideoStorageService {
  static const maxPublicSeconds = 10;
  static const prefix = 'fsva:';
  static const _maxBytes = 8 * 1024 * 1024;
  static const _chunkBytes = 400 * 1024;

  static bool isVideoFile(XFile file) {
    final name = file.name.toLowerCase();
    final mime = (file.mimeType ?? '').toLowerCase();
    return mime.startsWith('video/') ||
        name.endsWith('.mp4') ||
        name.endsWith('.mov') ||
        name.endsWith('.webm') ||
        name.endsWith('.m4v');
  }

  static bool isChunkedRef(String? value) {
    return value != null && value.startsWith(prefix);
  }

  static bool isVideoUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    final lower = value.toLowerCase();
    return isChunkedRef(value) ||
        lower.startsWith('data:video/') ||
        lower.contains('/videos/') ||
        lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.webm') ||
        lower.contains('video/');
  }

  Future<String> upload({
    required String folder,
    required XFile file,
    bool publicClip = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const VideoUploadFailure('Sign in again, then submit the video.');
    }
    try {
      var ready = file;
      if (publicClip) {
        ready = await preparePublicVideo(file);
      }
      final bytes = Uint8List.fromList(await ready.readAsBytes());
      if (bytes.isEmpty) {
        throw const VideoUploadFailure(
          'The video file was empty. Record again and submit.',
        );
      }
      if (bytes.length > _maxBytes) {
        throw const VideoUploadFailure(
          'This clip is still too large after compression. Record a shorter indoor clip.',
        );
      }
      final firestore = FirebaseFirestore.instance;
      final doc = firestore.collection('video_assets').doc();
      final chunks = <Uint8List>[];
      for (var offset = 0; offset < bytes.length; offset += _chunkBytes) {
        final end = (offset + _chunkBytes > bytes.length)
            ? bytes.length
            : offset + _chunkBytes;
        chunks.add(bytes.sublist(offset, end));
      }
      await doc.set({
        'uid': user.uid,
        'folder': folder,
        'chunkCount': chunks.length,
        'byteLength': bytes.length,
        'createdAt': FieldValue.serverTimestamp(),
      });
      final batch = firestore.batch();
      for (var i = 0; i < chunks.length; i++) {
        batch.set(doc.collection('chunks').doc('$i'), {
          'd': base64Encode(chunks[i]),
        });
      }
      await batch.commit();
      return '$prefix${doc.id}';
    } on VideoUploadFailure {
      rethrow;
    } on FirebaseException catch (error) {
      debugPrint('Firestore video save failed: ${error.code} ${error.message}');
      throw VideoUploadFailure(_message(error));
    } catch (error) {
      debugPrint('Video save failed: $error');
      throw VideoUploadFailure(_message(error));
    }
  }

  Future<Uint8List> loadBytes(String ref) async {
    if (!isChunkedRef(ref)) {
      throw const VideoUploadFailure('This video link is not valid.');
    }
    final id = ref.substring(prefix.length);
    final doc = FirebaseFirestore.instance.collection('video_assets').doc(id);
    final meta = await doc.get();
    if (!meta.exists) {
      throw const VideoUploadFailure('This video is no longer available.');
    }
    final count = (meta.data()?['chunkCount'] as num?)?.toInt() ?? 0;
    final parts = <int>[];
    for (var i = 0; i < count; i++) {
      final chunk = await doc.collection('chunks').doc('$i').get();
      final encoded = chunk.data()?['d'] as String?;
      if (encoded == null || encoded.isEmpty) {
        throw const VideoUploadFailure('This video is incomplete.');
      }
      parts.addAll(base64Decode(encoded));
    }
    return Uint8List.fromList(parts);
  }

  String _message(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Firestore rules blocked the video. Deploy the updated firestore.rules, then try again.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'Could not save the video to Firestore. Try again on a stronger signal.';
        case 'resource-exhausted':
          return 'This clip is too large for the free Firestore limit. Record a shorter clip.';
      }
    }
    return 'The video could not be saved. Try a shorter clip.';
  }
}
