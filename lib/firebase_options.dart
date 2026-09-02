import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

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
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB6-nTwiYN91yAZhn0N3pp70auSNPJ45XU',
    appId: '1:966639409242:web:c305e1d207344af67ae063',
    messagingSenderId: '966639409242',
    projectId: 'agrifarms-174f9',
    authDomain: 'agrifarms-174f9.firebaseapp.com',
    storageBucket: 'agrifarms-174f9.firebasestorage.app',
    measurementId: 'G-C86KEQSTPM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA4Fubf-vaBgyeZu6gwOIc7hLQ0Y-Jwji0',
    appId: '1:966639409242:android:61b355644fc2b9c47ae063',
    messagingSenderId: '966639409242',
    projectId: 'agrifarms-174f9',
    storageBucket: 'agrifarms-174f9.firebasestorage.app',
  );
}
