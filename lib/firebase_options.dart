// File được sinh tự động bởi Antigravity.
// Cấu hình Mock Firebase cho Web để phục vụ mục đích chạy thử và kiểm nghiệm UI.
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD2ZBXm6CL9Hd_xWgELVbNqcI4Ilwu_n7I',
    appId: '1:76237350372:web:f4653b24ac2e16937f93f1',
    messagingSenderId: '76237350372',
    projectId: 'love-lang-c78dd',
    authDomain: 'love-lang-c78dd.firebaseapp.com',
    storageBucket: 'love-lang-c78dd.firebasestorage.app',
    measurementId: 'G-LY8745NW9M',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBJMrGBa7WOOKdZI3GIktsgm6FsjfRT1z8',
    appId: '1:76237350372:android:b4d4849c916187c77f93f1',
    messagingSenderId: '76237350372',
    projectId: 'love-lang-c78dd',
    storageBucket: 'love-lang-c78dd.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDP8XJZxz8YBgziUPrpheXID2FJq-VLY_A',
    appId: '1:76237350372:ios:994bfedf3e8953997f93f1',
    messagingSenderId: '76237350372',
    projectId: 'love-lang-c78dd',
    storageBucket: 'love-lang-c78dd.firebasestorage.app',
    iosBundleId: 'com.lovelang.app',
  );
}
