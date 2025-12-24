import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/features/profile/model/profile_model.dart';

class ProfileService {
  final _db = FirebaseFirestore.instance;
  final String collection = 'profiles';

  Future<ProfileModel> fetchProfile(String uid) async {
    final doc = await _db.collection(collection).doc(uid).get();
    if (!doc.exists) {
      throw Exception('Profile not found');
    }
    return ProfileModel.fromDoc(doc);
  }

  Future<void> createProfileIfNotExists({
    required String uid,
    required String name,
    required String email,
  }) async {
    final ref = _db.collection(collection).doc(uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'uid': uid,
        'name': name,
        'email': email,
        'misNo': null,
        'department': null,
        'batchId': null,
        'coCurricular': null,
        'contactNo': null,
        'parentContactNo': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateProfile({
    required String uid,
    String? misNo,
    String? department,
    String? coCurricular,
    String? contactNo,
    String? parentContactNo,
  }) async {
    await _db.collection(collection).doc(uid).update({
      'misNo': misNo,
      'department': department,
      'coCurricular': coCurricular,
      'contactNo': contactNo,
      'parentContactNo': parentContactNo,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
