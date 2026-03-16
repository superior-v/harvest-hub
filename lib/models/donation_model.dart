import 'package:flutter/material.dart'; // ADD THIS LINE
class Donation {
  final String id;
  final String title;
  final String description;
  final String category;
  final String quantity;
  final String condition;
  final String donorId;
  final String donorName;
  final String location;
  final String status; // 'active', 'matched', 'completed', 'cancelled'
  final DateTime postedDate;
  final List<String> imageUrls;
  final String? recipientId;
  final String? recipientName;
  final DateTime? pickupDate;
  final int views;
  final int requests;

  Donation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.quantity,
    required this.condition,
    required this.donorId,
    required this.donorName,
    required this.location,
    required this.status,
    required this.postedDate,
    this.imageUrls = const [],
    this.recipientId,
    this.recipientName,
    this.pickupDate,
    this.views = 0,
    this.requests = 0,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'quantity': quantity,
      'condition': condition,
      'donorId': donorId,
      'donorName': donorName,
      'location': location,
      'status': status,
      'postedDate': postedDate.toIso8601String(),
      'imageUrls': imageUrls,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'pickupDate': pickupDate?.toIso8601String(),
      'views': views,
      'requests': requests,
    };
  }

  // Create from Firebase Map
  factory Donation.fromMap(Map<String, dynamic> map) {
    return Donation(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity'] ?? '',
      condition: map['condition'] ?? '',
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      location: map['location'] ?? '',
      status: map['status'] ?? 'active',
      postedDate: DateTime.parse(map['postedDate']),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      recipientId: map['recipientId'],
      recipientName: map['recipientName'],
      pickupDate: map['pickupDate'] != null ? DateTime.parse(map['pickupDate']) : null,
      views: map['views'] ?? 0,
      requests: map['requests'] ?? 0,
    );
  }

  // Helper method to get status color
  static Color getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF2196F3); // Blue
      case 'matched':
        return const Color(0xFFFF9800); // Orange
      case 'completed':
        return const Color(0xFF4CAF50); // Green
      case 'cancelled':
        return const Color(0xFF9E9E9E); // Gray
      default:
        return const Color(0xFF757575);
    }
  }

  // Helper method to get status icon
  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.visibility;
      case 'matched':
        return Icons.handshake;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}