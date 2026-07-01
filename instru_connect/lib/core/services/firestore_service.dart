import 'package:firebase_auth/firebase_auth.dart';
import 'package:instru_connect/core/constants/firestore_collections.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/demo/demo_account.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/features/auth/domain/repositories/user_bootstrap_repository.dart';

class FirestoreService implements UserBootstrapRepository {
  final _db = FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>> getOrCreateUser({
    required User firebaseUser,
  }) async {
    final ref = _db
        .collection(FirestoreCollections.users)
        .doc(firebaseUser.uid);
    final normalizedEmail = firebaseUser.email?.trim().toLowerCase();
    final normalizedName = firebaseUser.displayName?.trim() ?? '';

    final baseData = <String, dynamic>{
      'uid': firebaseUser.uid,
      'email': normalizedEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final isDemoAccount = DemoAccount.isDemoEmail(normalizedEmail);

    if (normalizedName.isNotEmpty) {
      baseData['name'] = normalizedName;
    }

    final defaultRole = isDemoAccount ? AppRoles.admin : AppRoles.student;

    if (isDemoAccount) {
      baseData.addAll({
        'name': DemoAccount.name,
        'role': AppRoles.admin,
        'isDemoAccount': true,
      });
    }

    final snap = await ref.get(const GetOptions(source: Source.serverAndCache));

    if (!snap.exists) {
      final data = {
        ...baseData,
        'role': defaultRole,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await ref.set(data);
      return data;
    }

    final data = snap.data() ?? <String, dynamic>{};
    final updates = <String, dynamic>{...baseData};

    if (isDemoAccount || (data['role'] ?? '').toString().trim().isEmpty) {
      updates['role'] = defaultRole;
    }

    await ref.set(updates, SetOptions(merge: true));
    return {...data, ...updates};
  }
}
