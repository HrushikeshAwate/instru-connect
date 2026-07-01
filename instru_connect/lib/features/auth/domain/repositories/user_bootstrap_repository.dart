import 'package:firebase_auth/firebase_auth.dart';

abstract interface class UserBootstrapRepository {
  Future<Map<String, dynamic>> getOrCreateUser({required User firebaseUser});
}
