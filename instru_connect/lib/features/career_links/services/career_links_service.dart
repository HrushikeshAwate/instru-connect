import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/core/demo/demo_mode.dart';

class CareerLinkItem {
  const CareerLinkItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final String id;
  final String title;
  final String subtitle;
  final String url;

  CareerLinkItem copyWith({String? url}) {
    return CareerLinkItem(
      id: id,
      title: title,
      subtitle: subtitle,
      url: url ?? this.url,
    );
  }
}

class CareerLinksService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<CareerLinkItem> defaultLinks = [
    CareerLinkItem(
      id: 'syInternships',
      title: 'Second Year Internships',
      subtitle: 'Internship sheet for SY students',
      url: 'https://example.com/sy-internships',
    ),
    CareerLinkItem(
      id: 'tyInternships',
      title: 'Third Year Internships',
      subtitle: 'Internship sheet for TY students',
      url: 'https://example.com/ty-internships',
    ),
    CareerLinkItem(
      id: 'finalYearInternships',
      title: 'Final Year Internships',
      subtitle: 'Internship sheet for final year students',
      url: 'https://example.com/final-year-internships',
    ),
    CareerLinkItem(
      id: 'finalYearPlacements',
      title: 'Final Year Placements',
      subtitle: 'Placement sheet for final year students',
      url: 'https://example.com/final-year-placements',
    ),
  ];

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('careerLinks').doc('default');

  Stream<List<CareerLinkItem>> streamLinks() {
    if (DemoMode.isActive) return Stream.value(defaultLinks);

    return _doc.snapshots().map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      return defaultLinks.map((link) {
        final storedUrl = (data[link.id] ?? '').toString().trim();
        return link.copyWith(url: storedUrl.isEmpty ? link.url : storedUrl);
      }).toList();
    });
  }

  Future<void> updateLink({
    required String linkId,
    required String url,
    required String uid,
  }) async {
    DemoMode.ensureCanWrite();

    await _doc.set({
      linkId: url.trim(),
      'updatedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
