import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadXFile({
    required String path,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    return uploadBytes(path: path, bytes: bytes, contentType: _contentType(file));
  }

  Future<String> uploadBytes({
    required String path,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    final ref = _storage.ref(path);
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: contentType),
    );
    return ref.getDownloadURL();
  }

  String _contentType(XFile file) {
    final mime = file.mimeType;
    if (mime != null && mime.isNotEmpty) return mime;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.mp4')) return 'video/mp4';
    return 'image/jpeg';
  }
}
