import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:instru_connect/core/demo/demo_mode.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadNoticeAttachment({
    required Uint8List bytes,
    required String fileName,
    required String noticeId,
  }) async {
    DemoMode.ensureCanWrite();

    final ref = _storage.ref().child('notices').child(noticeId).child(fileName);

    final taskSnapshot = await ref.putData(bytes);

    if (taskSnapshot.state == TaskState.success) {
      return await ref.getDownloadURL();
    } else {
      throw Exception('Attachment upload failed');
    }
  }
}
