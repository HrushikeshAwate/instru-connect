import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  final String uid;
  final String name;
  final String email;

  final String? misNo;
  final String? department;
  final String? batchId;

  final String? coCurricular;
  final String? contactNo;
  final String? parentContactNo;

  final Timestamp createdAt;
  final Timestamp updatedAt;

  ProfileModel({
    required this.uid,
    required this.name,
    required this.email,
    this.misNo,
    this.department,
    this.batchId,
    this.coCurricular,
    this.contactNo,
    this.parentContactNo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileModel(
      uid: data['uid'],
      name: data['name'],
      email: data['email'],
      misNo: data['misNo'],
      department: data['department'],
      batchId: data['batchId'],
      coCurricular: data['coCurricular'],
      contactNo: data['contactNo'],
      parentContactNo: data['parentContactNo'],
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'misNo': misNo,
      'department': department,
      'batchId': batchId,
      'coCurricular': coCurricular,
      'contactNo': contactNo,
      'parentContactNo': parentContactNo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
