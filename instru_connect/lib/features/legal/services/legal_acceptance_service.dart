import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:instru_connect/features/legal/legal_content.dart';

class LegalAcceptanceService {
  static const String _acceptedLegalVersionKey = 'accepted_legal_version';
  static const String _acceptedLegalTimestampKey = 'accepted_legal_timestamp';

  Future<bool> hasAcceptedCurrentVersion() async {
    final prefs = await SharedPreferences.getInstance();
    final acceptedVersion = prefs.getInt(_acceptedLegalVersionKey) ?? 0;
    return acceptedVersion >= LegalContent.currentLegalVersion;
  }

  Future<int> getAcceptedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_acceptedLegalVersionKey) ?? 0;
  }

  Future<void> acceptCurrentVersion() async {
    final prefs = await SharedPreferences.getInstance();
    final acceptedAtIso = DateTime.now().toUtc().toIso8601String();

    await prefs.setInt(
      _acceptedLegalVersionKey,
      LegalContent.currentLegalVersion,
    );
    await prefs.setString(_acceptedLegalTimestampKey, acceptedAtIso);

    await _tryWriteAuditRecord(acceptedAtIso);
  }

  Future<void> syncAcceptanceAuditIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final acceptedVersion = prefs.getInt(_acceptedLegalVersionKey) ?? 0;

    if (acceptedVersion < LegalContent.currentLegalVersion) {
      return;
    }

    final acceptedAtIso =
        prefs.getString(_acceptedLegalTimestampKey) ??
        DateTime.now().toUtc().toIso8601String();

    await _tryWriteAuditRecord(acceptedAtIso);
  }

  Future<void> _tryWriteAuditRecord(String acceptedAtIso) async {
    try {
      await _writeAuditRecordIfPossible(acceptedAtIso);
    } catch (error, stackTrace) {
      debugPrint('Legal acceptance audit sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _writeAuditRecordIfPossible(String acceptedAtIso) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final auditRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('legal_acceptances')
        .doc('v${LegalContent.currentLegalVersion}');

    final existing = await auditRef.get();
    if (existing.exists) return;

    await auditRef.set({
      'legalVersion': LegalContent.currentLegalVersion,
      'acceptedAt': FieldValue.serverTimestamp(),
      'acceptedAtDevice': acceptedAtIso,
      'acceptedByUid': user.uid,
      'acceptedByEmail': user.email,
      'source': 'terms_acceptance_gate',
      'termsTitle': LegalContent.termsTitle,
      'privacyTitle': LegalContent.privacyTitle,
      'termsText': LegalContent.termsFullText,
      'privacyText': LegalContent.privacyFullText,
    });
  }
}
