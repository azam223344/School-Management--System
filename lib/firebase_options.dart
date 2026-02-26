// ignore_for_file: lines_longer_than_80_chars
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC8KLrdhg-Pxg3HTVoGjDxacUJI4CUNiUw',
    appId: '1:587798503861:web:replace_with_real_web_app_id',
    messagingSenderId: '587798503861',
    projectId: 'auth-488',
    authDomain: 'auth-488.firebaseapp.com',
    storageBucket: 'auth-488.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC8KLrdhg-Pxg3HTVoGjDxacUJI4CUNiUw',
    appId: '1:587798503861:android:3f95b1966a25888ffdb9fc',
    messagingSenderId: '587798503861',
    projectId: 'auth-488',
    storageBucket: 'auth-488.firebasestorage.app',
  );
}
