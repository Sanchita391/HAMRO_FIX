import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase project hamrofix-d10d8.
/// Android values come from google-services.json.
/// Web values come from the HamroFixWeb app in the same Firebase project.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC5GP1D4XmYh2SKyiDKj_3bDumHLA9hoSM',
    appId: '1:461081246021:web:5eebfc1536175b35cf262c',
    messagingSenderId: '461081246021',
    projectId: 'hamrofix-d10d8',
    authDomain: 'hamrofix-d10d8.firebaseapp.com',
    storageBucket: 'hamrofix-d10d8.firebasestorage.app',
    measurementId: 'G-CFP54255X0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAE5LIHSuG7z5s3XccHRaFw-LbfBF-2pMg',
    appId: '1:461081246021:android:766f49815d7022d5cf262c',
    messagingSenderId: '461081246021',
    projectId: 'hamrofix-d10d8',
    storageBucket: 'hamrofix-d10d8.firebasestorage.app',
  );
}
