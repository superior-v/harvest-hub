import 'package:cloud_firestore/cloud_firestore.dart';

class DonationModel {
  final String id;
  final String donorId;
  final String title;
  final String description;
  final String category;
  final String condition;
  final String quantity;
  final String location;
  final double? latitude;
  final double? longitude;
  final List<String> imageUrls;
  final DateTime? expiryDate;
  final String status; // available, reserved, completed
  final DateTime? createdAt;
  final int views;
  final int requests;

  // ── Food Safety fields ──────────────────────────────────────────────────────
  /// When the food was cooked / prepared
  final DateTime? cookedAt;

  /// The deadline by which the food must be picked up (drives countdown timer)
  final DateTime? pickupDeadline;

  /// e.g. ['Veg', 'Halal']
  final List<String> dietaryTags;

  /// e.g. ['Nuts', 'Dairy']
  final List<String> allergenTags;

  DonationModel({
    required this.id,
    required this.donorId,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.quantity,
    required this.location,
    this.latitude,
    this.longitude,
    required this.imageUrls,
    this.expiryDate,
    this.status = 'available',
    this.createdAt,
    this.views = 0,
    this.requests = 0,
    this.cookedAt,
    this.pickupDeadline,
    this.dietaryTags = const [],
    this.allergenTags = const [],
  });

  // From Firestore
  factory DonationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DonationModel(
      id: doc.id,
      donorId: data['donorId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      condition: data['condition'] ?? '',
      quantity: data['quantity'] ?? '',
      location: data['location'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'available',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      views: data['views'] ?? 0,
      requests: data['requests'] ?? 0,
      cookedAt: (data['cookedAt'] as Timestamp?)?.toDate(),
      pickupDeadline: (data['pickupDeadline'] as Timestamp?)?.toDate(),
      dietaryTags: List<String>.from(data['dietaryTags'] ?? []),
      allergenTags: List<String>.from(data['allergenTags'] ?? []),
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'donorId': donorId,
      'title': title,
      'description': description,
      'category': category,
      'condition': condition,
      'quantity': quantity,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'views': views,
      'requests': requests,
      'cookedAt': cookedAt != null ? Timestamp.fromDate(cookedAt!) : null,
      'pickupDeadline': pickupDeadline != null ? Timestamp.fromDate(pickupDeadline!) : null,
      'dietaryTags': dietaryTags,
      'allergenTags': allergenTags,
    };
  }
}