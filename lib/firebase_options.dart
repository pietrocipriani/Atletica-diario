// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA7Ys59Rrbw9rpCUfBRvSRFXwk2Qzrf7Ko',
    appId: '1:263594363462:web:806d326a429f8047da5847',
    messagingSenderId: '263594363462',
    projectId: 'atletica-7f96b',
    authDomain: 'atletica-7f96b.firebaseapp.com',
    databaseURL: 'https://atletica-7f96b.firebaseio.com',
    storageBucket: 'atletica-7f96b.appspot.com',
    measurementId: 'G-3NBJY9N98W',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDTr5JsbDRsJNqG0o9i_Hq8MbeABAkoYUs',
    appId: '1:263594363462:android:612b2c9dc68519b7da5847',
    messagingSenderId: '263594363462',
    projectId: 'atletica-7f96b',
    databaseURL: 'https://atletica-7f96b.firebaseio.com',
    storageBucket: 'atletica-7f96b.appspot.com',
  );
}
