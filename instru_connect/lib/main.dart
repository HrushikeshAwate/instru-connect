import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:instru_connect/core/services/push_notification_service.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);
  await PushNotificationService().initialize();

  // --- ADD THIS SECTION TO CONTROL CACHE SIZE ---
  // This prevents the "70MB cache" issue by capping it at 15MB
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 15728640, // 15MB in bytes (15 * 1024 * 1024)
  );
  // ----------------------------------------------₹

  runApp(const App());
}
