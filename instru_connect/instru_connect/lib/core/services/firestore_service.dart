import 'package:firebase_auth/firebase_auth.dart';
import 'package:instru_connect/core/constants/firestore_collections.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getOrCreateUser({
    required User firebaseUser,
  }) async {
    final ref = _db
        .collection(FirestoreCollections.users)
        .doc(firebaseUser.uid);

    final snap = await ref.get();

    if (!snap.exists) {
      final data = {
        'uid': firebaseUser.uid,
        'name': firebaseUser.displayName ?? '',
        'email': firebaseUser.email,
        'role': AppRoles.student,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await ref.set(data);
      return data;
    }

    if (snap.exists) {
      final data = snap.data()!;

      if ((data['name'] == null || data['name'] == '') &&
          firebaseUser.displayName != null) {
        await ref.update({'name': firebaseUser.displayName});
      }

      return data;
    }

    return snap.data()!;
  }
}
