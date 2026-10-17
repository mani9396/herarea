import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for HER AREA Vendor Application.
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD2bINKvz13Hmlg2fyEXiQH93z_jqcLStE',
    appId: '1:175996357308:web:1b966be0d630fa1c5cdeb9',
    messagingSenderId: '175996357308',
    projectId: 'her-area',
    authDomain: 'her-area.firebaseapp.com',
    storageBucket: 'her-area.firebasestorage.app',
    measurementId: 'G-484E7XXQJ3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD7TRAz1AgzPaHxIBMz7u2iLMkoo0LzXyI',
    appId: '1:175996357308:android:50ba3195943814f75cdeb9',
    messagingSenderId: '175996357308',
    projectId: 'her-area',
    storageBucket: 'her-area.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBiZq6Et6xG1Di8_-qknwvNAbhFVG5tK5I',
    appId: '1:175996357308:ios:141947064ef782cb5cdeb9',
    messagingSenderId: '175996357308',
    projectId: 'her-area',
    storageBucket: 'her-area.firebasestorage.app',
    iosBundleId: 'com.herarea.vendor',
  );
}
