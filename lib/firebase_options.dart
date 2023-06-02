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
        return ios;
      case TargetPlatform.macOS:
        return macos;
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
    apiKey: 'AIzaSyCHrj1Q4OuzPm45bMMBIrNoilc7QTkFs9s',
    appId: '1:325017033419:web:96dbf7b78f91be437d594e',
    messagingSenderId: '325017033419',
    projectId: 'carender-1faae',
    authDomain: 'carender-1faae.firebaseapp.com',
    databaseURL: 'https://carender-1faae-default-rtdb.firebaseio.com',
    storageBucket: 'carender-1faae.appspot.com',
    measurementId: 'G-WX6R4PMVCK',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC9l4xWxVmW5S9vIuealpaj10DQioanSc4',
    appId: '1:325017033419:android:a9319a39841bc5687d594e',
    messagingSenderId: '325017033419',
    projectId: 'carender-1faae',
    databaseURL: 'https://carender-1faae-default-rtdb.firebaseio.com',
    storageBucket: 'carender-1faae.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB2As-Ng8L8vRon3U25RJCaDnb7FZhRD1g',
    appId: '1:325017033419:ios:3b4a224cf2fad7247d594e',
    messagingSenderId: '325017033419',
    projectId: 'carender-1faae',
    databaseURL: 'https://carender-1faae-default-rtdb.firebaseio.com',
    storageBucket: 'carender-1faae.appspot.com',
    iosClientId: '325017033419-i22ao47iph195uemq9o07q8msdtqa9r0.apps.googleusercontent.com',
    iosBundleId: 'com.example.photo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB2As-Ng8L8vRon3U25RJCaDnb7FZhRD1g',
    appId: '1:325017033419:ios:3b4a224cf2fad7247d594e',
    messagingSenderId: '325017033419',
    projectId: 'carender-1faae',
    databaseURL: 'https://carender-1faae-default-rtdb.firebaseio.com',
    storageBucket: 'carender-1faae.appspot.com',
    iosClientId: '325017033419-i22ao47iph195uemq9o07q8msdtqa9r0.apps.googleusercontent.com',
    iosBundleId: 'com.example.photo',
  );
}
