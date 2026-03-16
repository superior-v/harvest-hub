import 'package:flutter/material.dart';

class DonationRequest {
  final String id;
  final String donationId;
  final String donationTitle;
  final String donationCategory;
  final String recipientId;
  final String recipientName;
  final String donorId;
  final String donorName;
  final String status; // 'pending', 'approved', 'rejected', 'completed'
  final String message;
  final DateTime requestDate;
  final DateTime? responseDate;
  final String? pickupAddress;
  final DateTime? scheduledPickupDate;
  final String? donorResponse;

  DonationRequest({
    required this.id,
    required this.donationId,
    required this.donationTitle,
    required this.donationCategory,
    required this.recipientId,
    required this.recipientName,
    required this.donorId,
    required this.donorName,
    required this.status,
    required this.message,
    required this.requestDate,
    this.responseDate,
    this.pickupAddress,
    this.scheduledPickupDate,
    this.donorResponse,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donationId': donationId,
      'donationTitle': donationTitle,
      'donationCategory': donationCategory,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'donorId': donorId,
      'donorName': donorName,
      'status': status,
      'message': message,
      'requestDate': requestDate.toIso8601String(),
      'responseDate': responseDate?.toIso8601String(),
      'pickupAddress': pickupAddress,
      'scheduledPickupDate': scheduledPickupDate?.toIso8601String(),
      'donorResponse': donorResponse,
    };
  }

  // Create from Firebase Map
  factory DonationRequest.fromMap(Map<String, dynamic> map) {
    return DonationRequest(
      id: map['id'] ?? '',
      donationId: map['donationId'] ?? '',
      donationTitle: map['donationTitle'] ?? '',
      donationCategory: map['donationCategory'] ?? '',
      recipientId: map['recipientId'] ?? '',
      recipientName: map['recipientName'] ?? '',
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      status: map['status'] ?? 'pending',
      message: map['message'] ?? '',
      requestDate: DateTime.parse(map['requestDate']),
      responseDate: map['responseDate'] != null ? DateTime.parse(map['responseDate']) : null,
      pickupAddress: map['pickupAddress'],
      scheduledPickupDate: map['scheduledPickupDate'] != null ? DateTime.parse(map['scheduledPickupDate']) : null,
      donorResponse: map['donorResponse'],
    );
  }

  // Helper method to get status color
  static Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      case 'approved':
        return const Color(0xFF4CAF50); // Green
      case 'rejected':
        return const Color(0xFFF44336); // Red
      case 'completed':
        return const Color(0xFF2196F3); // Blue
      case 'cancelled':
        return const Color(0xFF757575); // Gray
      default:
        return const Color(0xFF757575); // Gray
    }
  }

  // Helper method to get status icon
  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.remove_circle;
      default:
        return Icons.info;
    }
  }

  // Helper to get status display text
  static String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Awaiting Response';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Declined';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}
