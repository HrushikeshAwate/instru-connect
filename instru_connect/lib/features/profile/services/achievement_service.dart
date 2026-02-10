import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class AchievementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =====================================================
  // FETCH ACHIEVEMENTS (STREAM, LIFO)
  // =====================================================

  Stream<List<Map<String, dynamic>>> fetchAchievements(String uid) {
    return _db
        .collection('achievements')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAtClient', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  // =====================================================
  // PICK FILE (PDF / IMAGE)
  // =====================================================

  Future<PlatformFile?> pickAchievementFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return result.files.single;
  }

  // =====================================================
  // UPLOAD ACHIEVEMENT
  // =====================================================

  Future<void> uploadAchievement({
    required String uid,
    required String title,
    required String event,
    required String rank,
    required String score,
    required String description,
    required PlatformFile file,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    Uint8List bytes;

    if (file.bytes != null) {
      bytes = file.bytes!;
    } else if (file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    } else {
      throw Exception('Invalid file selected');
    }

    final storageRef = _storage.ref(
      'achievements/$uid/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
    );

    final metadata = SettableMetadata(
      contentType: _contentTypeFromExtension(file.extension),
    );

    await storageRef.putData(bytes, metadata);

    final downloadUrl = await storageRef.getDownloadURL();

    await _db.collection('achievements').add({
      'uid': uid,
      'title': title,
      'event': event,
      'rank': rank,
      'score': score,
      'description': description,
      'certificateUrl': downloadUrl,
      'certificateName': file.name,
      'certificateType': file.extension ?? '',
      'createdAtClient': DateTime.now().millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // =====================================================
  // EXPORT ALL ACHIEVEMENTS (CSV FOR EXCEL)
  // =====================================================

  Future<String> exportAllAchievementsCsv() async {
    final achievementsSnap = await _db
        .collection('achievements')
        .orderBy('createdAtClient', descending: true)
        .get();

    final userCache = <String, Map<String, dynamic>>{};
    final profileCache = <String, Map<String, dynamic>>{};
    final batchCache = <String, String>{};

    final rows = <List<dynamic>>[
      [
        'Role',
        'Batch',
        'Name',
        'MIS No',
        'Achievement',
        'Event',
        'Rank',
        'Score',
        'Description',
        'Certificate URL',
      ]
    ];

    for (final doc in achievementsSnap.docs) {
      final data = doc.data();
      final uid = (data['uid'] ?? '').toString();

      if (uid.isEmpty) {
        continue;
      }

      if (!userCache.containsKey(uid)) {
        final userDoc = await _db.collection('users').doc(uid).get();
        if (userDoc.exists) {
          userCache[uid] = userDoc.data() ?? {};
        } else {
          userCache[uid] = {};
        }
      }

      if (!profileCache.containsKey(uid)) {
        final profileDoc = await _db.collection('profiles').doc(uid).get();
        if (profileDoc.exists) {
          profileCache[uid] = profileDoc.data() ?? {};
        } else {
          profileCache[uid] = {};
        }
      }

      final user = userCache[uid] ?? {};
      final profile = profileCache[uid] ?? {};

      final batchId = (profile['batchId'] ?? '').toString();
      String batchName = '';
      if (batchId.isNotEmpty) {
        if (!batchCache.containsKey(batchId)) {
          final batchDoc = await _db.collection('batches').doc(batchId).get();
          batchCache[batchId] = batchDoc.data()?['name']?.toString() ?? '';
        }
        batchName = batchCache[batchId] ?? '';
      }

      final role = (user['role'] ?? '').toString();
      final name = (user['name'] ?? profile['name'] ?? '').toString();
      final misNo = (profile['misNo'] ?? '').toString();

      rows.add([
        role,
        batchName,
        name,
        misNo,
        (data['title'] ?? '').toString(),
        (data['event'] ?? '').toString(),
        (data['rank'] ?? '').toString(),
        (data['score'] ?? '').toString(),
        (data['description'] ?? '').toString(),
        (data['certificateUrl'] ?? '').toString(),
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/achievements_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(filePath);
    await file.writeAsString(csv);

    return filePath;
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
