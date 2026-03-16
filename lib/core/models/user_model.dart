import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'donor', 'recipient', 'farmer'
  final int totalDonations;
  final int totalRequests;
  final int impactPoints;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.totalDonations = 0,
    this.totalRequests = 0,
    this.impactPoints = 0,
    this.createdAt,
  });

  // From Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'recipient',
      totalDonations: data['totalDonations'] ?? 0,
      totalRequests: data['totalRequests'] ?? 0,
      impactPoints: data['impactPoints'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'totalDonations': totalDonations,
      'totalRequests': totalRequests,
      'impactPoints': impactPoints,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}