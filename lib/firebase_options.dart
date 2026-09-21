import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Generated from the existing Android `google-services.json`
/// (project: hamrofix-d10d8, package: app.hamro_fix).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAE5LIHSuG7z5s3XccHRaFw-LbfBF-2pMg',
    appId: '1:461081246021:android:766f49815d7022d5cf262c',
    messagingSenderId: '461081246021',
    projectId: 'hamrofix-d10d8',
    storageBucket: 'hamrofix-d10d8.firebasestorage.app',
  );
}
