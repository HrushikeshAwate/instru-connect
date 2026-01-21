import 'package:cloud_firestore/cloud_firestore.dart';

class CertificationModel {
  final String id;
  final String uid;
  final String title;
  final String issuer;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final Timestamp createdAt;

  CertificationModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.issuer,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.createdAt,
  });

  factory CertificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CertificationModel(
      id: doc.id,
      uid: data['uid'],
      title: data['title'],
      issuer: data['issuer'],
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileType: data['fileType'],
      createdAt: data['createdAt'],
    );
  }
}
