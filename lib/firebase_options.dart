// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyDdSg2ZPgJsnAe1LcW8TjzFAl2KrTEit_k',
    appId: '1:155756794559:web:fd7bad2ebdac0f6b5fec0a',
    messagingSenderId: '155756794559',
    projectId: 'convetchat',
    authDomain: 'convetchat.firebaseapp.com',
    storageBucket: 'convetchat.firebasestorage.app',
    measurementId: 'G-5T2X5BV2VC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBWAyKNGpDbnwNyYm2lK5lbwzcfdt8NYB4',
    appId: '1:155756794559:android:fda82915242384d35fec0a',
    messagingSenderId: '155756794559',
    projectId: 'convetchat',
    storageBucket: 'convetchat.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA9RpqgmnBL_HjwHVr6SgXuOPcc0Bf__eM',
    appId: '1:155756794559:ios:1f17d80f7b4256c85fec0a',
    messagingSenderId: '155756794559',
    projectId: 'convetchat',
    storageBucket: 'convetchat.firebasestorage.app',
    iosBundleId: 'com.convet.convetchat',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA9RpqgmnBL_HjwHVr6SgXuOPcc0Bf__eM',
    appId: '1:155756794559:ios:1f17d80f7b4256c85fec0a',
    messagingSenderId: '155756794559',
    projectId: 'convetchat',
    storageBucket: 'convetchat.firebasestorage.app',
    iosBundleId: 'com.convet.convetchat',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDdSg2ZPgJsnAe1LcW8TjzFAl2KrTEit_k',
    appId: '1:155756794559:web:568b95bb4ee0efea5fec0a',
    messagingSenderId: '155756794559',
    projectId: 'convetchat',
    authDomain: 'convetchat.firebaseapp.com',
    storageBucket: 'convetchat.firebasestorage.app',
    measurementId: 'G-55Q1JZRC2F',
  );
}
