import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationTokenService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registerToken(String uid) async {
    await _messaging.requestPermission();

    if (Platform.isIOS) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken == null) {
        return;
      }
    }

    try {
      final token = await _messaging.getToken();
      // Debug print for verification
      // ignore: avoid_print
      print('FCM token: $token');
      if (token != null && token.isNotEmpty) {
        await _saveToken(uid, token);
      }
    } catch (e) {
      // ignore: avoid_print
      print('FCM token error: $e');
      return;
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      if (newToken.isNotEmpty) {
        await _saveToken(uid, newToken);
      }
    });
  }

  Future<void> _saveToken(String uid, String token) async {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token);

    await ref.set({
      'token': token,
      'platform': Platform.operatingSystem,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
