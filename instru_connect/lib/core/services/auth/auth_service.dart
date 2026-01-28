import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔐 ONLY THIS GMAIL CAN BE ADMIN
  static const String allowedAdminGmail =
      'instru.admin@gmail.com'; // CHANGE THIS

  // =====================================================
  // CURRENT USER
  // =====================================================
  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // =====================================================
  // MICROSOFT SIGN-IN (UNCHANGED)
  // =====================================================
  Future<UserCredential> signInWithMicrosoft() async {
    final provider = OAuthProvider('microsoft.com');

    provider.setCustomParameters({
      'tenant': 'b4c6b754-54e3-41e4-a8da-304355c62816',
    });

    provider.setScopes([
      'openid',
      'profile',
      'email',
      'offline_access',
    ]);

    return await _auth.signInWithProvider(provider);
  }

  // =====================================================
  // GOOGLE SIGN-IN (ADMIN ONLY)
  // =====================================================
//   Future<void> signInWithGoogleAdminOnly() async {
//   final GoogleSignIn googleSignIn = GoogleSignIn(
//     scopes: ['email'],
//   );

//   // 1️⃣ Trigger Google account picker
//   final GoogleSignInAccount? googleUser =
//       await googleSignIn.signIn();

//   if (googleUser == null) {
//     throw Exception('Google sign-in cancelled');
//   }

//   // 2️⃣ Get auth details
//   final GoogleSignInAuthentication googleAuth =
//       await googleUser.authentication;

//   final credential = GoogleAuthProvider.credential(
//     accessToken: googleAuth.accessToken,
//     idToken: googleAuth.idToken,
//   );

//   // 3️⃣ Firebase Auth
//   final userCredential =
//       await _auth.signInWithCredential(credential);

//   final user = userCredential.user!;
//   final email = user.email!.toLowerCase();

//   // 4️⃣ Enforce admin-only Gmail
//   if (email != allowedAdminGmail.toLowerCase()) {
//     await _auth.signOut();
//     throw Exception('Access denied: Admin only');
//   }

//   // 5️⃣ Firestore role bootstrap
//   final userRef = _db.collection('users').doc(user.uid);
//   final doc = await userRef.get();

//   if (!doc.exists) {
//     await userRef.set({
//       'email': email,
//       'role': 'admin',
//       'createdAt': FieldValue.serverTimestamp(),
//     });
//     return;
//   }

//   if (doc.data()?['role'] != 'admin') {
//     await _auth.signOut();
//     throw Exception('Access denied: Admin only');
//   }
// }

  // =====================================================
  // SIGN OUT
  // =====================================================
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
