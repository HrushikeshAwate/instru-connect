import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class CertificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =====================================================
  // FETCH CERTIFICATES (STREAM)
  // =====================================================

  Stream<List<Map<String, dynamic>>> fetchCertificates(String uid) {
    return _db
        .collection('certifications')
        .where('uid', isEqualTo: uid)
        // 🔥 ORDER BY CLIENT TIMESTAMP (NEVER NULL)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  // =====================================================
  // PICK FILE (PDF / IMAGE)
  // =====================================================

  Future<PlatformFile?> pickCertificateFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true, // 🔥 REQUIRED FOR iOS SAFETY
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
    // ---------------------------------------------------
    // AUTH CHECK
    // ---------------------------------------------------
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // ---------------------------------------------------
    // PREPARE FILE BYTES (iOS SAFE)
    // ---------------------------------------------------
    Uint8List bytes;

    if (file.bytes != null) {
      bytes = file.bytes!;
    } else if (file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    } else {
      throw Exception('Invalid file selected');
    }

    // ---------------------------------------------------
    // STORAGE PATH (MATCHES RULES)
    // certifications/{uid}/{timestamp_filename}
    // ---------------------------------------------------
    final storageRef = _storage.ref(
      'certifications/$uid/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
    );

    final metadata = SettableMetadata(
      contentType: _contentTypeFromExtension(file.extension),
    );

    // ---------------------------------------------------
    // UPLOAD USING putData() (FIXES -1017)
    // ---------------------------------------------------
    await storageRef.putData(bytes, metadata);

    final downloadUrl = await storageRef.getDownloadURL();

    // ---------------------------------------------------
    // SAVE METADATA TO FIRESTORE
    // ---------------------------------------------------
    await _db.collection('certifications').add({
      'uid': uid,
      'title': title,
      'issuer': issuer,
      'fileUrl': downloadUrl,
      'fileName': file.name,
      'fileType': file.extension ?? '',

      // 🔥 CLIENT TIMESTAMP (FOR QUERY ORDERING)
      'createdAtClient': DateTime.now().millisecondsSinceEpoch,

      // SERVER TIMESTAMP (FOR AUDIT)
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // =====================================================
  // CONTENT TYPE HELPER
  // =====================================================

  String _contentTypeFromExtension(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
