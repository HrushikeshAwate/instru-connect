import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:instru_connect/features/profile/model/certification_model.dart';

class CertificationService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Stream<List<CertificationModel>> fetchCertificates(String uid) {
  return _db
      .collection('certifications')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((snap) =>
          snap.docs.map(CertificationModel.fromDoc).toList());
}


  Future<void> uploadCertificate({
    required String uid,
    required String title,
    required String issuer,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result == null) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    final ext = fileName.split('.').last;

    final ref = _storage
        .ref()
        .child('certifications/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName');

    final uploadTask = await ref.putFile(file);
    final url = await uploadTask.ref.getDownloadURL();

    await _db.collection('certifications').add({
      'uid': uid,
      'title': title,
      'issuer': issuer,
      'fileUrl': url,
      'fileName': fileName,
      'fileType': ext,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
