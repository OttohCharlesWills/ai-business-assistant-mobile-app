import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCTJgAH4rgpdjzCEPwT73-LYjwKkjNE2qs',
    appId: '1:568678497982:android:d675075a50c814ff1ae8ef',
    messagingSenderId: '568678497982',
    projectId: 'ai-business-assistant-fad4d',
    storageBucket: 'ai-business-assistant-fad4d.firebasestorage.app',
  );
}