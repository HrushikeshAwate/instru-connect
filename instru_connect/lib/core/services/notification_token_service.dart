import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationTokenService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registerToken(String uid) async {
    await _messaging.requestPermission();

    if (Platform.isIOS) {
      String? apnsToken = await _messaging.getAPNSToken();
      var attempts = 0;
      while (apnsToken == null && attempts < 5) {
        await Future<void>.delayed(const Duration(seconds: 1));
        apnsToken = await _messaging.getAPNSToken();
        attempts++;
      }
      if (apnsToken == null) {
        return;
      }
    }

    try {
      final token = await _messaging.getToken();
      if (kDebugMode) {
        debugPrint('FCM token: $token');
      }
      if (token != null && token.isNotEmpty) {
        await _saveToken(uid, token);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token error: $e');
      }
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
