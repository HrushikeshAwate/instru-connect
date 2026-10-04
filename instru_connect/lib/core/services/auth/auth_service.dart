import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:instru_connect/core/demo/demo_account.dart';
import 'package:instru_connect/core/services/session_cache_service.dart';
import 'package:instru_connect/features/auth/domain/repositories/auth_repository.dart';

class AuthService implements AuthRepository {
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
  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  static bool isAllowedCollegeEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return _allowedEmailSuffixes.any(normalized.endsWith);
  }

  // =====================================================
  // MICROSOFT SIGN-IN (UNCHANGED)
  // =====================================================
  @override
  Future<void> signInWithMicrosoft() async {
    final currentUser = _auth.currentUser;
    final currentEmail = currentUser?.email?.trim().toLowerCase();

    if (currentUser != null && isAllowedCollegeEmail(currentEmail)) {
      return;
    }

    await _signInWithMicrosoftInternal(retryOnRecoverableFailure: true);
  }

  @override
  Future<void> signInWithDemoMode({
    required String id,
    required String password,
  }) async {
    await _safeSignOut();

    try {
      final email = _demoEmailForId(id);
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _prepareDemoUserProfile(credential.user);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _friendlyDemoSignInMessage(e),
      );
    }
  }

  String _demoEmailForId(String id) {
    final normalized = id.trim().toLowerCase();
    if (normalized == DemoAccount.email || normalized == DemoAccount.misNo) {
      return DemoAccount.email;
    }

    throw FirebaseAuthException(
      code: 'invalid-demo-id',
      message: 'Enter the valid demo account ID or email.',
    );
  }

  Future<void> _prepareDemoUserProfile(User? user) async {
    if (user == null) {
      throw FirebaseAuthException(
        code: 'demo-sign-in-failed',
        message: 'Demo sign-in could not create a Firebase session.',
      );
    }

    final email = user.email?.trim().toLowerCase();
    if (!isAllowedCollegeEmail(email)) {
      await _safeSignOut();
      throw FirebaseAuthException(
        code: 'unauthorized-domain',
        message: 'The demo account is not using an approved college domain.',
      );
    }

    if ((user.displayName ?? '').trim().isEmpty) {
      await user.updateDisplayName(DemoAccount.name);
    }
  }

  String _friendlyDemoSignInMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
        return 'Demo Mode needs Email/Password sign-in enabled in Firebase Authentication.';
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Invalid demo ID or password.';
      case 'network-request-failed':
        return 'Demo Mode could not reach Firebase. Please check your internet connection and try again.';
      default:
        return e.message ?? 'Demo Mode could not sign in. Please try again.';
    }
  }

  Future<UserCredential> _signInWithMicrosoftInternal({
    required bool retryOnRecoverableFailure,
  }) async {
    await _prepareFreshProviderFlow();

    final provider = OAuthProvider('microsoft.com');

    provider.setCustomParameters({
      'tenant': 'b4c6b754-54e3-41e4-a8da-304355c62816',
      'prompt': 'select_account',
    });

    try {
      final credential = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
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
    } on FirebaseAuthException catch (e, stackTrace) {
      if (_isMissingInitialStateText(e.message ?? '') ||
          _isMissingInitialStateText(e.code)) {
        await _safeSignOut();
        throw FirebaseAuthException(
          code: 'missing-initial-state',
          message: _missingInitialStateMessage,
        );
      }

      if (_shouldRetrySignIn(e) && retryOnRecoverableFailure) {
        await _safeSignOut();
        return _signInWithMicrosoftInternal(retryOnRecoverableFailure: false);
      }

      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Microsoft sign-in failed: ${e.code}',
        fatal: false,
      );

      throw FirebaseAuthException(
        code: e.code,
        message:
            '${_friendlySignInMessage(e)}\n\n[diag] code=${e.code} | ${e.message ?? 'no message'}',
      );
    } catch (e) {
      if (_isMissingInitialStateText(e.toString())) {
        await _safeSignOut();
        throw FirebaseAuthException(
          code: 'missing-initial-state',
          message: _missingInitialStateMessage,
        );
      }

      if (retryOnRecoverableFailure) {
        await _safeSignOut();
        return _signInWithMicrosoftInternal(retryOnRecoverableFailure: false);
      }

      throw FirebaseAuthException(
        code: 'sign-in-failed',
        message:
            'Sign-in could not be completed. Please try again. If the account was deleted from Firebase, ask an admin to re-create its access.'
            '\n\n[diag] $e',
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
        _isMissingInitialStateText(message) ||
        message.contains('public encryption key') ||
        message.contains('generic idp');
  }

  static const String _missingInitialStateMessage =
      'Microsoft sign-in lost its secure browser session. Please close the Microsoft sign-in sheet and tap Sign in again. If it keeps happening, restart the app once or clear Safari website data for firebaseapp.com and login.microsoftonline.com.';

  bool _isMissingInitialStateText(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('missing initial state') ||
        normalized.contains('sessionstorage is inaccessible') ||
        normalized.contains('session storage is inaccessible') ||
        normalized.contains('storage-partitioned browser');
  }

  String _friendlySignInMessage(FirebaseAuthException e) {
    final message = e.message ?? '';

    if (_isMissingInitialStateText(message) ||
        _isMissingInitialStateText(e.code)) {
      return _missingInitialStateMessage;
    }

    final normalizedMessage = message.toLowerCase();

    if (normalizedMessage.contains('public encryption key') ||
        normalizedMessage.contains('generic idp')) {
      return 'The secure sign-in session could not be prepared. Please try again. If it keeps happening after reinstalling or clearing app data, the Firebase mobile auth configuration may need to be refreshed.';
    }

    if (normalizedMessage.contains('package certificate hash')) {
      return 'This Play Store build is not linked to Firebase yet. Ask the app administrator to register the Play App Signing SHA-1 and SHA-256 certificates in Firebase. Sign-in will work once the configuration has propagated.';
    }

    switch (e.code) {
      case 'web-context-cancelled':
      case 'web-operation-cancelled':
        return 'Sign-in was interrupted. Please try again and keep the Microsoft pop-up open until it finishes.';
      case 'popup-blocked':
        return 'The browser blocked the Microsoft sign-in pop-up. Please allow pop-ups for InstruConnect and try again.';
      case 'popup-closed-by-user':
        return 'The Microsoft sign-in pop-up was closed before sign-in finished.';
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
  @override
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
