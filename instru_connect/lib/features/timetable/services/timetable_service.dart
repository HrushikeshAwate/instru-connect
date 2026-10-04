import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:instru_connect/core/demo/demo_mode.dart';

class TimetableDocument {
  const TimetableDocument({
    required this.year,
    required this.fileName,
    required this.storagePath,
    this.updatedAt,
  });

  final String year;
  final String fileName;
  final String storagePath;
  final DateTime? updatedAt;

  factory TimetableDocument.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final updatedAtValue = data['updatedAt'];
    return TimetableDocument(
      year: (data['year'] ?? id).toString(),
      fileName: (data['fileName'] ?? 'Timetable PDF').toString(),
      storagePath: (data['storagePath'] ?? '').toString(),
      updatedAt: updatedAtValue is Timestamp ? updatedAtValue.toDate() : null,
    );
  }
}

class TimetableService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<TimetableDocument?> fetchTimetable(String year) async {
    if (DemoMode.isActive) return null;

    final doc = await _db.collection('timetables').doc(_docIdFor(year)).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    final timetable = TimetableDocument.fromFirestore(doc.id, data);
    if (timetable.storagePath.trim().isEmpty) return null;
    return timetable;
  }

  Future<String> downloadTimetableToFile({
    required TimetableDocument timetable,
    required Directory directory,
  }) async {
    if (DemoMode.isActive) {
      throw Exception('App Review Demo cannot download stored timetable data.');
    }

    final file = File(
      '${directory.path}/${_docIdFor(timetable.year)}_uploaded_timetable.pdf',
    );
    await _storage.ref(timetable.storagePath).writeToFile(file);
    return file.path;
  }

  Future<void> uploadTimetable({
    required String year,
    required File file,
    required String originalFileName,
    required String uid,
    required String role,
  }) async {
    DemoMode.ensureCanWrite();

    final docId = _docIdFor(year);
    final safeFileName = originalFileName.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]+'),
      '_',
    );
    final storagePath = 'timetables/$docId/$safeFileName';
    final ref = _storage.ref(storagePath);

    await ref.putFile(file, SettableMetadata(contentType: 'application/pdf'));

    await _db.collection('timetables').doc(docId).set({
      'year': year,
      'fileName': originalFileName,
      'storagePath': storagePath,
      'updatedBy': uid,
      'updatedByRole': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, Map<String, dynamic>>> fetchTimetableCells(
    String year,
  ) async {
    final snapshot = await _db
        .collection('timetables')
        .doc(_docIdFor(year))
        .collection('cells')
        .get();

    return {for (final doc in snapshot.docs) doc.id: doc.data()};
  }

  Stream<Map<String, Map<String, dynamic>>> streamTimetableCells(String year) {
    if (DemoMode.isActive) return Stream.value(const {});

    return _db
        .collection('timetables')
        .doc(_docIdFor(year))
        .collection('cells')
        .snapshots()
        .map(
          (snapshot) => {for (final doc in snapshot.docs) doc.id: doc.data()},
        );
  }

  Future<void> updateTimetableCell({
    required String year,
    required String day,
    required int slotIndex,
    required String title,
    required String type,
    required String uid,
    required String role,
  }) async {
    DemoMode.ensureCanWrite();

    if (role != 'faculty' && role != 'admin') {
      throw Exception('Only faculty or admin can edit timetables.');
    }

    final cellRef = _db
        .collection('timetables')
        .doc(_docIdFor(year))
        .collection('cells')
        .doc('${day.trim().toUpperCase()}_$slotIndex');

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      await cellRef.delete();
    } else {
      await cellRef.set({
        'day': day.trim().toUpperCase(),
        'slotIndex': slotIndex,
        'title': trimmedTitle,
        'type': type,
        'updatedBy': uid,
        'updatedByRole': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  String _docIdFor(String year) => year.trim().toLowerCase();
}
