import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// ✅ Microsoft login handled fully by Firebase
  Future<UserCredential> signInWithMicrosoft() async {
    final provider = OAuthProvider('microsoft.com');

    provider.setCustomParameters({
    'tenant': 'b4c6b754-54e3-41e4-a8da-304355c62816', // 👈 IMPORTANT
  });

    provider.setScopes([
      'openid',
      'profile',
      'email',
      'offline_access',
    ]);

    return await _auth.signInWithProvider(provider);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
