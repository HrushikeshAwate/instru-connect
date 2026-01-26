import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class CertificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // =====================================================
  // FETCH CERTIFICATES (STREAM)
  // =====================================================

  Stream<List<Map<String, dynamic>>> fetchCertificates(String uid) {
    return _db
        .collection('certifications')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((d) => d.data()).toList(),
        );
  }

  // =====================================================
  // PICK FILE (PDF or IMAGE)
  // =====================================================

  Future<PlatformFile?> pickCertificateFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return result.files.single;
  }

  // =====================================================
  // UPLOAD CERTIFICATE
  // =====================================================

  Future<void> uploadCertificate({
    required String uid,
    required String title,
    required String issuer,
    required PlatformFile file,
  }) async {
    final fileRef = _storage.ref(
      'certifications/$uid/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
    );

    // Upload file to Firebase Storage
    await fileRef.putFile(File(file.path!));

    // Get download URL
    final downloadUrl = await fileRef.getDownloadURL();

    // Save metadata to Firestore
    await _db.collection('certifications').add({
      'uid': uid,
      'title': title,
      'issuer': issuer,
      'fileUrl': downloadUrl,
      'fileName': file.name,
      'fileType': file.extension ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
