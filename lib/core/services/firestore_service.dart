import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get donations => _firestore.collection('donations');
  CollectionReference get requests => _firestore.collection('requests');
  CollectionReference get users => _firestore.collection('users');

  // ==================== USER PROFILE METHODS ====================

  /// Create a new user profile in Firestore
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String name,
    required String role,
  }) async {
    try {
      debugPrint('🔵 Creating user profile for: $uid');

      await users.doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'totalDonations': 0,
        'totalRequests': 0,
        'impactPoints': 0,
        'isActive': true,
        'phoneNumber': '',
        'location': '',
        'profileImageUrl': '',
      }, SetOptions(merge: true));

      debugPrint('✅ User profile created successfully');
    } catch (e) {
      debugPrint('❌ Error creating user profile: $e');
      rethrow;
    }
  }

  /// Get user profile by UID
  Future<DocumentSnapshot> getUserProfile(String uid) async {
    try {
      debugPrint('🔵 Fetching user profile for: $uid');
      final doc = await users.doc(uid).get();

      if (doc.exists) {
        debugPrint('✅ User profile found');
      } else {
        debugPrint('⚠️ User profile not found');
      }

      return doc;
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      debugPrint('🔵 Updating user profile for: $uid');

      data['updatedAt'] = FieldValue.serverTimestamp();

      await users.doc(uid).update(data);
      debugPrint('✅ User profile updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  /// Check if user profile exists
  Future<bool> userProfileExists(String uid) async {
    try {
      final doc = await users.doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error checking user profile: $e');
      return false;
    }
  }

  /// Increment user stats
  Future<void> incrementUserStats(String uid, String field) async {
    try {
      await users.doc(uid).update({
        field: FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Error incrementing user stats: $e');
    }
  }

  // ==================== DONATION METHODS ====================

  /// Create a new donation
  Future<String> createDonation({
    required String donorId,
    required String title,
    required String description,
    required String category,
    required String condition,
    required String quantity,
    required String location,
    double? latitude,
    double? longitude,
    required List<String> imageUrls,
    DateTime? expiryDate,
    String? donorName,
    String? donorPhone,
  }) async {
    try {
      debugPrint('🔵 Creating donation: $title');

      final docRef = await donations.add({
        'donorId': donorId,
        'donorName': donorName ?? '',
        'donorPhone': donorPhone ?? '',
        'title': title,
        'description': description,
        'category': category,
        'condition': condition,
        'quantity': quantity,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'imageUrls': imageUrls,
        'expiryDate': expiryDate,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'views': 0,
        'requestCount': 0,
        'isActive': true,
      });

      // Increment donor's total donations
      await incrementUserStats(donorId, 'totalDonations');

      debugPrint('✅ Donation created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating donation: $e');
      rethrow;
    }
  }

  /// Get donations stream with filters
  Stream<QuerySnapshot> getDonationsStream({
    String? category,
    String? status,
    String? donorId,
    int limit = 50,
  }) {
    try {
      Query query = donations.where('isActive', isEqualTo: true).orderBy('createdAt', descending: true);

      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (donorId != null) {
        query = query.where('donorId', isEqualTo: donorId);
      }

      return query.limit(limit).snapshots();
    } catch (e) {
      debugPrint('❌ Error getting donations stream: $e');
      rethrow;
    }
  }

  /// Get single donation by ID
  Future<DocumentSnapshot> getDonation(String donationId) async {
    try {
      return await donations.doc(donationId).get();
    } catch (e) {
      debugPrint('❌ Error getting donation: $e');
      rethrow;
    }
  }

  /// Get user's donations
  Stream<QuerySnapshot> getUserDonations(String userId) {
    try {
      return donations.where('donorId', isEqualTo: userId).where('isActive', isEqualTo: true).orderBy('createdAt', descending: true).snapshots();
    } catch (e) {
      debugPrint('❌ Error getting user donations: $e');
      rethrow;
    }
  }

  /// Update donation
  Future<void> updateDonation(String donationId, Map<String, dynamic> data) async {
    try {
      debugPrint('🔵 Updating donation: $donationId');

      data['updatedAt'] = FieldValue.serverTimestamp();

      await donations.doc(donationId).update(data);
      debugPrint('✅ Donation updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating donation: $e');
      rethrow;
    }
  }

  /// Update donation status
  Future<void> updateDonationStatus(String donationId, String status) async {
    try {
      debugPrint('🔵 Updating donation status to: $status');

      await donations.doc(donationId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Donation status updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating donation status: $e');
      rethrow;
    }
  }

  /// Delete donation (soft delete)
  Future<void> deleteDonation(String donationId) async {
    try {
      debugPrint('🔵 Deleting donation: $donationId');

      // Soft delete - just mark as inactive
      await donations.doc(donationId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Donation deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting donation: $e');
      rethrow;
    }
  }

  /// Permanently delete donation
  Future<void> permanentlyDeleteDonation(String donationId) async {
    try {
      debugPrint('🔵 Permanently deleting donation: $donationId');

      await donations.doc(donationId).delete();

      debugPrint('✅ Donation permanently deleted');
    } catch (e) {
      debugPrint('❌ Error permanently deleting donation: $e');
      rethrow;
    }
  }

  /// Increment donation view count
  Future<void> incrementViews(String donationId) async {
    try {
      await donations.doc(donationId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('❌ Error incrementing views: $e');
    }
  }

  /// Search donations
  Future<List<DocumentSnapshot>> searchDonations(String searchTerm) async {
    try {
      final querySnapshot = await donations
          .where('isActive', isEqualTo: true)
          .orderBy('title')
          .startAt([
            searchTerm
          ])
          .endAt([
            searchTerm + '\uf8ff'
          ])
          .limit(20)
          .get();

      return querySnapshot.docs;
    } catch (e) {
      debugPrint('❌ Error searching donations: $e');
      return [];
    }
  }

  // ==================== REQUEST METHODS ====================

  /// Create a new request
  Future<String> createRequest({
    required String recipientId,
    required String donationId,
    required String message,
    String? recipientName,
    String? recipientEmail,
  }) async {
    try {
      debugPrint('🔵 Creating request for donation: $donationId');

      // Check if request already exists
      final existingRequest = await requests.where('recipientId', isEqualTo: recipientId).where('donationId', isEqualTo: donationId).where('status', whereIn: [
        'pending',
        'approved',
        'accepted'
      ]).get();

      if (existingRequest.docs.isNotEmpty) {
        throw 'You have already requested this donation';
      }

      // Pull donation + donor metadata so both donor and recipient views can render directly.
      final donationDoc = await donations.doc(donationId).get();
      final donationData = donationDoc.data() as Map<String, dynamic>?;
      final donorId = donationData?['donorId'] as String? ?? '';

      String donorName = '';
      if (donorId.isNotEmpty) {
        final donorDoc = await users.doc(donorId).get();
        final donorData = donorDoc.data() as Map<String, dynamic>?;
        donorName = donorData?['name'] as String? ?? '';
      }

      final docRef = await requests.add({
        'recipientId': recipientId,
        'recipientName': recipientName ?? '',
        'recipientEmail': recipientEmail ?? '',
        'donorId': donorId,
        'donorName': donorName,
        'donationId': donationId,
        'donationTitle': donationData?['title'] ?? '',
        'donationCategory': donationData?['category'] ?? 'Other',
        'pickupAddress': donationData?['location'] ?? '',
        'message': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Increment request count on donation
      await donations.doc(donationId).update({
        'requestCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Increment user's total requests
      await incrementUserStats(recipientId, 'totalRequests');

      debugPrint('✅ Request created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating request: $e');
      rethrow;
    }
  }

  /// Get user's requests (as recipient)
  Stream<QuerySnapshot> getUserRequests(String userId) {
    try {
      return requests.where('recipientId', isEqualTo: userId).snapshots();
    } catch (e) {
      debugPrint('❌ Error getting user requests: $e');
      rethrow;
    }
  }

  /// Get incoming requests for donor
  Stream<QuerySnapshot> getDonorIncomingRequests(String donorId) {
    try {
      return requests.where('donorId', isEqualTo: donorId).snapshots();
    } catch (e) {
      debugPrint('❌ Error getting donor incoming requests: $e');
      rethrow;
    }
  }

  /// Get requests for a specific donation
  Stream<QuerySnapshot> getDonationRequests(String donationId) {
    try {
      return requests.where('donationId', isEqualTo: donationId).where('isActive', isEqualTo: true).orderBy('createdAt', descending: true).snapshots();
    } catch (e) {
      debugPrint('❌ Error getting donation requests: $e');
      rethrow;
    }
  }

  /// Get requests for donor's donations
  Future<List<DocumentSnapshot>> getDonorRequests(String donorId) async {
    try {
      // First get all donor's donations
      final donationsSnapshot = await donations.where('donorId', isEqualTo: donorId).get();

      if (donationsSnapshot.docs.isEmpty) {
        return [];
      }

      // Get donation IDs
      final donationIds = donationsSnapshot.docs.map((doc) => doc.id).toList();

      // Get all requests for these donations
      final requestsSnapshot = await requests.where('donationId', whereIn: donationIds).where('isActive', isEqualTo: true).orderBy('createdAt', descending: true).get();

      return requestsSnapshot.docs;
    } catch (e) {
      debugPrint('❌ Error getting donor requests: $e');
      return [];
    }
  }

  /// Update request status
  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      debugPrint('🔵 Updating request status to: $status');

      final normalizedStatus = status == 'accepted' ? 'approved' : status;

      await requests.doc(requestId).update({
        'status': normalizedStatus,
        'responseDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If accepted, update donation status
      if (normalizedStatus == 'approved') {
        final requestDoc = await requests.doc(requestId).get();
        final data = requestDoc.data() as Map<String, dynamic>?; // ← FIX HERE
        final donationId = data?['donationId'] as String?;

        if (donationId != null) {
          await updateDonationStatus(donationId, 'reserved');
        }
      }

      debugPrint('✅ Request status updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating request status: $e');
      rethrow;
    }
  }

  /// Cancel request
  Future<void> cancelRequest(String requestId) async {
    try {
      debugPrint('🔵 Cancelling request: $requestId');

      final requestDoc = await requests.doc(requestId).get();
      final data = requestDoc.data() as Map<String, dynamic>?; // ← FIX HERE
      final donationId = data?['donationId'] as String?;

      // Update request status
      await requests.doc(requestId).update({
        'status': 'cancelled',
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Decrement request count on donation
      if (donationId != null) {
        await donations.doc(donationId).update({
          'requestCount': FieldValue.increment(-1),
        });
      }

      debugPrint('✅ Request cancelled successfully');
    } catch (e) {
      debugPrint('❌ Error cancelling request: $e');
      rethrow;
    }
  }

  // ==================== ANALYTICS & STATISTICS ====================

  /// Get donation statistics for a user
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final userDoc = await users.doc(userId).get();

      if (!userDoc.exists) {
        return {
          'totalDonations': 0,
          'totalRequests': 0,
          'impactPoints': 0,
        };
      }

      final data = userDoc.data() as Map<String, dynamic>;
      return {
        'totalDonations': data['totalDonations'] ?? 0,
        'totalRequests': data['totalRequests'] ?? 0,
        'impactPoints': data['impactPoints'] ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting user stats: $e');
      return {
        'totalDonations': 0,
        'totalRequests': 0,
        'impactPoints': 0,
      };
    }
  }

  /// Get total donations count
  Future<int> getTotalDonationsCount() async {
    try {
      final snapshot = await donations.where('isActive', isEqualTo: true).get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Error getting total donations count: $e');
      return 0;
    }
  }

  /// Get donations by category count
  Future<Map<String, int>> getDonationsByCategory() async {
    try {
      final snapshot = await donations.where('isActive', isEqualTo: true).get();

      final Map<String, int> categoryCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?; // ← FIX HERE
        final category = data?['category'] as String? ?? 'Other';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      return categoryCounts;
    } catch (e) {
      debugPrint('❌ Error getting donations by category: $e');
      return {};
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Batch update donations
  Future<void> batchUpdateDonations(
    List<String> donationIds,
    Map<String, dynamic> updates,
  ) async {
    try {
      final batch = _firestore.batch();

      updates['updatedAt'] = FieldValue.serverTimestamp();

      for (final id in donationIds) {
        batch.update(donations.doc(id), updates);
      }

      await batch.commit();
      debugPrint('✅ Batch update completed for ${donationIds.length} donations');
    } catch (e) {
      debugPrint('❌ Error in batch update: $e');
      rethrow;
    }
  }

  /// Clean up expired donations
  Future<void> cleanupExpiredDonations() async {
    try {
      final now = DateTime.now();
      final snapshot = await donations.where('expiryDate', isLessThan: now).where('isActive', isEqualTo: true).get();

      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': 'expired',
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ Cleaned up ${snapshot.docs.length} expired donations');
    } catch (e) {
      debugPrint('❌ Error cleaning up expired donations: $e');
    }
  }
}
