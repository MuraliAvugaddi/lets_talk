
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCnYgiwI8kQpdQhJ3-FUrzMoHf9he6Dnx4',
    appId: '1:823434055852:android:47568933bdd73fe62ccf09',
    messagingSenderId: '823434055852',
    projectId: 'let-s-speak-cbc27',
    storageBucket: 'let-s-speak-cbc27.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCp0DAq0B7Pvy1oZW7HO0DjuxIS3mawZXQ',
    appId: '1:823434055852:ios:f3d4eeeebfd4cd292ccf09',
    messagingSenderId: '823434055852',
    projectId: 'let-s-speak-cbc27',
    storageBucket: 'let-s-speak-cbc27.firebasestorage.app',
    iosBundleId: 'com.surendra.letsspeakapp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAQpwUhta-3kk1f2CB0n-H3aY0Crm8cheM',
    appId: '1:823434055852:web:bfd82393ad0626132ccf09',
    messagingSenderId: '823434055852',
    projectId: 'let-s-speak-cbc27',
    authDomain: 'let-s-speak-cbc27.firebaseapp.com',
    storageBucket: 'let-s-speak-cbc27.firebasestorage.app',
    measurementId: 'G-ZTJ76WGK4Y',
  );
}
