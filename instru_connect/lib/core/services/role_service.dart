import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/constants/firestore_collections.dart';

class RoleService {
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetchFullUser(String uid) async {
  final doc = await _db
      .collection(FirestoreCollections.users)
      .doc(uid)
      .get();

  if (!doc.exists) {
    throw Exception('User document missing');
  }

  return doc.data()!;
}


  Future<String> fetchUserRole(String uid) async {
    final doc = await _db
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    if (!doc.exists) {
      throw Exception('User document missing');
    }

    final role = doc.data()!['role'];

    if (!AppRoles.all.contains(role)) {
      throw Exception('Invalid role: $role');
    }

    return role;
  }
}
