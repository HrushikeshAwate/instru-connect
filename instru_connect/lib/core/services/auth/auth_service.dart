import 'package:firebase_auth/firebase_auth.dart';
import 'package:instru_connect/core/services/session_cache_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const List<String> _allowedEmailSuffixes = [
    '.instru@coeptech.ac.in',
    '@coeptech.ac.in',
  ];

  // 🔐 ONLY THIS GMAIL CAN BE ADMIN
  static const String allowedAdminGmail =
      'instru.admin@gmail.com'; // CHANGE THIS

  // =====================================================
  // CURRENT USER
  // =====================================================
  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  static bool isAllowedCollegeEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return _allowedEmailSuffixes.any(normalized.endsWith);
  }

  // =====================================================
  // MICROSOFT SIGN-IN (UNCHANGED)
  // =====================================================
  Future<void> signInWithMicrosoft() async {
    final currentUser = _auth.currentUser;
    final currentEmail = currentUser?.email?.trim().toLowerCase();

    if (currentUser != null && isAllowedCollegeEmail(currentEmail)) {
      return;
    }

    await _signInWithMicrosoftInternal(retryOnRecoverableFailure: true);
  }

  Future<UserCredential> _signInWithMicrosoftInternal({
    required bool retryOnRecoverableFailure,
  }) async {
    await _prepareFreshProviderFlow();

    final provider = OAuthProvider('microsoft.com');

    provider.setCustomParameters({
      'tenant': 'b4c6b754-54e3-41e4-a8da-304355c62816',
    });

    try {
      final credential = await _auth.signInWithProvider(provider);
      final email = credential.user?.email?.trim().toLowerCase();

      if (!isAllowedCollegeEmail(email)) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'unauthorized-domain',
          message:
              'Only official college email accounts are allowed to sign in.',
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      if (_shouldRetrySignIn(e) && retryOnRecoverableFailure) {
        await _safeSignOut();
        return _signInWithMicrosoftInternal(
          retryOnRecoverableFailure: false,
        );
      }

      throw FirebaseAuthException(
        code: e.code,
        message: _friendlySignInMessage(e),
      );
    } catch (_) {
      if (retryOnRecoverableFailure) {
        await _safeSignOut();
        return _signInWithMicrosoftInternal(
          retryOnRecoverableFailure: false,
        );
      }

      throw FirebaseAuthException(
        code: 'sign-in-failed',
        message:
            'Sign-in could not be completed. Please try again. If the account was deleted from Firebase, ask an admin to re-create its access.',
      );
    }
  }

  bool _shouldRetrySignIn(FirebaseAuthException e) {
    final message = (e.message ?? '').toLowerCase();

    return e.code == 'internal-error' ||
        e.code == 'invalid-credential' ||
        e.code == 'user-not-found' ||
        e.code == 'network-request-failed' ||
        e.code == 'web-context-cancelled' ||
        e.code == 'web-operation-cancelled' ||
        e.code == 'user-token-expired' ||
        message.contains('missing initial state') ||
        message.contains('public encryption key') ||
        message.contains('generic idp');
  }

  String _friendlySignInMessage(FirebaseAuthException e) {
    final message = (e.message ?? '').toLowerCase();

    if (message.contains('missing initial state')) {
      return 'The browser lost the Microsoft sign-in state before returning to the app. Please try again. If this keeps happening, set Chrome as the default browser and avoid privacy browsers for sign-in.';
    }

    if (message.contains('public encryption key') ||
        message.contains('generic idp')) {
      return 'The secure sign-in session could not be prepared. Please try again. If it keeps happening after reinstalling or clearing app data, the Firebase mobile auth configuration may need to be refreshed.';
    }

    switch (e.code) {
      case 'web-context-cancelled':
      case 'web-operation-cancelled':
        return 'Sign-in was interrupted. Please try again. If this account was deleted manually, the app may need one clean retry to re-link it.';
      case 'internal-error':
        return 'The account could not be restored cleanly from Firebase. Please try signing in again. If it still fails, ask an admin to re-create the user record.';
      case 'invalid-credential':
      case 'user-not-found':
        return 'Your previous sign-in state could not be reused cleanly. Please try again once. If it still fails, ask an admin to verify your account access.';
      case 'network-request-failed':
        return 'The sign-in request could not reach Firebase. Please check your internet connection and try again.';
      case 'user-token-expired':
        return 'Your previous session expired. Please sign in again.';
      default:
        return e.message ?? 'Sign-in failed. Please try again.';
    }
  }

  Future<void> _prepareFreshProviderFlow() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Ignore stale provider cleanup failures and continue.
    }
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
    await _safeSignOut();
  }

  Future<void> _safeSignOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Best-effort cleanup for broken sessions.
    } finally {
      await SessionCacheService.instance.clear();
    }
  }
}
