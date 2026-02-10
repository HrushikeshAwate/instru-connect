import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  final String id;
  final String uid;
  final String title;
  final String event;
  final String rank;
  final String score;
  final String description;
  final String certificateUrl;
  final String certificateName;
  final String certificateType;
  final int createdAtClient;
  final Timestamp? createdAt;

  AchievementModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.event,
    required this.rank,
    required this.score,
    required this.description,
    required this.certificateUrl,
    required this.certificateName,
    required this.certificateType,
    required this.createdAtClient,
    required this.createdAt,
  });

  factory AchievementModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AchievementModel(
      id: doc.id,
      uid: data['uid'],
      title: data['title'],
      event: data['event'] ?? '',
      rank: data['rank'] ?? '',
      score: data['score'] ?? '',
      description: data['description'] ?? '',
      certificateUrl: data['certificateUrl'] ?? '',
      certificateName: data['certificateName'] ?? '',
      certificateType: data['certificateType'] ?? '',
      createdAtClient: data['createdAtClient'] ?? 0,
      createdAt: data['createdAt'],
    );
  }
}
