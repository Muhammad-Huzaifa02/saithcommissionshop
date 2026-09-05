import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuE7GmpqQ-etGs968WPV8ZDyEHRkOUK3A',
    appId: '1:252739546969:android:1cb87c4252a61dc86f2648',
    messagingSenderId: '252739546969',
    projectId: 'saith-commission-shop-bda45',
    storageBucket: 'saith-commission-shop-bda45.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '252739546969',
    projectId: 'saith-commission-shop-bda45',
    storageBucket: 'saith-commission-shop-bda45.firebasestorage.app',
    iosBundleId: 'com.saith.commissionshop',
  );
}


