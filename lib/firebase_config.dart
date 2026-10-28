import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public Firebase app identifiers. Override with --dart-define-from-file
/// when using another Firebase project. See FIREBASE_SETUP.md.
class FirebaseConfig {
  static const apiKeyAndroid = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: 'AIzaSyAlWonYYEIo_httIG236b4JRQC0X_pG0nA',
  );
  static const apiKeyWeb = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: 'AIzaSyC3LyDwVzFqBRdn3RC99vaFFOSfexX4FHs',
  );
  static const appIdAndroid = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '1:138134406216:android:62368744a1be9831c4047d',
  );
  static const appIdWeb = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '1:138134406216:web:6bd9f398f7edf500c4047d',
  );
  static const projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'project-7180b607-0de7-493c-969',
  );
  static const senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '138134406216',
  );
  static const databaseUrl = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
    defaultValue: 'https://project-7180b607-0de7-493c-969-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
  static const storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'project-7180b607-0de7-493c-969.firebasestorage.app',
  );
  static const authDomainWeb = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
    defaultValue: 'project-7180b607-0de7-493c-969.firebaseapp.com',
  );
  static const webVapidKey = String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');

  static bool get isConfigured =>
      (kIsWeb ? apiKeyWeb.isNotEmpty : apiKeyAndroid.isNotEmpty) &&
      projectId.isNotEmpty &&
      senderId.isNotEmpty &&
      databaseUrl.isNotEmpty &&
      (kIsWeb ? appIdWeb.isNotEmpty : appIdAndroid.isNotEmpty);

  static FirebaseOptions get options => FirebaseOptions(
    apiKey: kIsWeb ? apiKeyWeb : apiKeyAndroid,
    appId: kIsWeb ? appIdWeb : appIdAndroid,
    messagingSenderId: senderId,
    projectId: projectId,
    databaseURL: databaseUrl,
    storageBucket: storageBucket.isEmpty ? null : storageBucket,
    authDomain: kIsWeb ? authDomainWeb : null,
  );
}
