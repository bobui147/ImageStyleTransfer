// The assignment explicitly asks for an FCM token. FlutterFire 17 deprecates
// token APIs in favor of installation IDs, but these APIs still return tokens.
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: FirebaseConfig.options);
  // Android and iOS display notification payloads in the background.
  // This handler is available for future data-message work.
}

class FirebaseMessagingService {
  FirebaseMessagingService({
    FirebaseMessaging? messaging,
    FirebaseDatabase? database,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _database =
           database ??
           FirebaseDatabase.instanceFor(
             app: Firebase.app(),
             databaseURL: FirebaseConfig.databaseUrl,
           );

  final FirebaseMessaging _messaging;
  final FirebaseDatabase _database;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  String? _currentToken;

  Future<String?> start({
    required String uid,
    required void Function(String) onToken,
    required void Function(RemoteMessage) onNotification,
    void Function(Object)? onError,
  }) async {
    await stop();
    if (kIsWeb && FirebaseConfig.webVapidKey.isEmpty) {
      throw const FormatException(
        'Thiếu FIREBASE_WEB_VAPID_KEY để nhận FCM trên web.',
      );
    }

    final permission = await _messaging.requestPermission();
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      throw const FormatException('Quyền nhận thông báo đã bị từ chối.');
    }

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      onNotification,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      onNotification,
    );
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) onNotification(initialMessage);

    final token = await _messaging.getToken(
      vapidKey: kIsWeb ? FirebaseConfig.webVapidKey : null,
    );
    if (token != null) {
      await _saveToken(uid, token);
      onToken(token);
    }
    _tokenSubscription = _messaging.onTokenRefresh.listen((refreshed) {
      _saveToken(uid, refreshed).then((_) => onToken(refreshed)).catchError((
        Object error,
      ) {
        onError?.call(error);
      });
    });
    return token;
  }

  Future<void> _saveToken(String uid, String token) async {
    await _database.ref('users/$uid').update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': ServerValue.timestamp,
    });
    _currentToken = token;
  }

  Future<void> signOut(String uid) async {
    await stop();
    if (_currentToken == null) return;
    final tokenRef = _database.ref('users/$uid/fcmToken');
    final current = await tokenRef.get();
    if (current.value == _currentToken) await tokenRef.remove();
    _currentToken = null;
    await _messaging.deleteToken();
  }

  Future<void> stop() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _tokenSubscription = null;
    _foregroundSubscription = null;
    _openedSubscription = null;
  }
}
