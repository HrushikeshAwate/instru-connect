import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/core/constants/profile_defaults.dart';
import 'package:instru_connect/core/demo/demo_mode.dart';
import 'package:instru_connect/features/profile/model/profile_model.dart';

class ProfileService {
  final _db = FirebaseFirestore.instance;
  final String collection = 'profiles';

  Future<String?> fetchBatchName(String batchId) async {
    final doc = await FirebaseFirestore.instance
        .collection('batches')
        .doc(batchId)
        .get();

    if (!doc.exists) return null;

    final data = doc.data();
    return data?['name'] as String?;
  }

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
        'department': ProfileDefaults.department,
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
    String? name,
    String? misNo,
    String? department,
    String? coCurricular,
    String? contactNo,
    String? parentContactNo,
  }) async {
    DemoMode.ensureCanWrite();

    final updates = <String, dynamic>{
      'misNo': misNo,
      'department': ProfileDefaults.department,
      'coCurricular': coCurricular,
      'contactNo': contactNo,
      'parentContactNo': parentContactNo,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      updates['name'] = trimmedName;
    }

    await _db.collection(collection).doc(uid).update(updates);

    final userUpdates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (trimmedName != null && trimmedName.isNotEmpty) {
      userUpdates['name'] = trimmedName;
    }
    if (misNo != null && misNo.trim().isNotEmpty) {
      userUpdates['misNo'] = misNo.trim();
    }
    if (userUpdates.length > 1) {
      await _db.collection('users').doc(uid).update(userUpdates);
    }
  }
}
