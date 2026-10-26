import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Represents a verified NGO, shelter, or community kitchen candidate for food dispatch
class RecipientCandidate {
  final String id;
  final String name;
  final String organizationType; // 'Shelter', 'Food Bank', 'Community Kitchen', 'Orphanage'
  final double latitude;
  final double longitude;
  final String address;
  final String phone;
  final int beneficiaryCapacity; // Number of people fed daily
  final List<String> acceptedCategories; // 'Cooked Meals', 'Raw Produce', 'Bakery', etc.
  final bool isVerified;
  final double averageResponseMinutes; // Historical pickup speed

  const RecipientCandidate({
    required this.id,
    required this.name,
    required this.organizationType,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phone,
    required this.beneficiaryCapacity,
    required this.acceptedCategories,
    this.isVerified = true,
    this.averageResponseMinutes = 15.0,
  });
}

/// Detailed Output of the Proximity & Urgency Matching Algorithm
class ProximityMatchResult {
  final RecipientCandidate recipient;
  final double distanceKm;
  final int estimatedEtaMinutes;
  final double matchScore; // 0.0 to 100.0%
  final String urgencyStatus; // 'CRITICAL DISPATCH', 'HIGH PRIORITY', 'STANDARD'
  final String matchReason;
  final bool isOptimalRoute;

  const ProximityMatchResult({
    required this.recipient,
    required this.distanceKm,
    required this.estimatedEtaMinutes,
    required this.matchScore,
    required this.urgencyStatus,
    required this.matchReason,
    this.isOptimalRoute = false,
  });

  String get formattedDistance {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()} m away';
    }
    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  String get formattedEta => '~$estimatedEtaMinutes mins drive';
}

/// HarvestHub Model 4: Proximity Matching & Priority Dispatch Algorithm
/// Computes geodesic distance, transit ETA, and multi-objective affinity scores.
class ProximityMatchingService {
  static final ProximityMatchingService _instance = ProximityMatchingService._internal();
  factory ProximityMatchingService() => _instance;
  ProximityMatchingService._internal();

  Interpreter? _interpreter;
  bool _isInitialized = false;

  /// Loads harvest_hub_dispatch_model.tflite from assets
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _interpreter = await Interpreter.fromAsset('assets/ml/harvest_hub_dispatch_model.tflite');
      _isInitialized = true;
      debugPrint('ProximityMatchingService: TFLite dispatch model loaded successfully.');
      return true;
    } catch (e) {
      debugPrint('ProximityMatchingService: TFLite load error: $e');
      return false;
    }
  }

  /// Fetches real registered NGO / shelter recipients from Firestore.
  /// Falls back to verified benchmark hubs if no real recipients are registered yet.
  Future<List<RecipientCandidate>> getAvailableCandidates() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'recipient')
          .get()
          .timeout(const Duration(seconds: 4));

      final List<RecipientCandidate> realRecipients = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lat = (data['latitude'] as num?)?.toDouble();
        final lon = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          realRecipients.add(
            RecipientCandidate(
              id: doc.id,
              name: data['name'] ?? 'Community Recipient',
              organizationType: data['organizationType'] ?? 'Community Kitchen',
              latitude: lat,
              longitude: lon,
              address: data['location'] ?? data['address'] ?? 'Local Area',
              phone: data['phoneNumber'] ?? '+91 98765 00000',
              beneficiaryCapacity: (data['capacity'] as num?)?.toInt() ?? 80,
              acceptedCategories: List<String>.from(data['acceptedCategories'] ?? ['Cooked', 'Food', 'Produce']),
              isVerified: data['isVerified'] ?? true,
              averageResponseMinutes: 15.0,
            ),
          );
        }
      }

      if (realRecipients.isNotEmpty) {
        debugPrint('ProximityMatchingService: Found ${realRecipients.length} REAL recipients in Firestore.');
        return realRecipients;
      }
    } catch (e) {
      debugPrint('ProximityMatchingService: Using verified benchmark hubs ($e)');
    }

    return _verifiedHubs;
  }

  // Verified food banks, shelters & community kitchens from Module 4
  static const List<RecipientCandidate> _verifiedHubs = [
    RecipientCandidate(
      id: 'hub_01',
      name: 'Central Community Kitchen',
      organizationType: 'Community Kitchen',
      latitude: 12.9740,
      longitude: 77.5910,
      address: 'Central Food Distribution Point, City Center',
      phone: '+91 98450 11223',
      beneficiaryCapacity: 120,
      acceptedCategories: ['Cooked', 'Cooked Meals', 'Bakery', 'Packaged', 'Packaged food', 'Food'],
      isVerified: true,
      averageResponseMinutes: 12.0,
    ),
    RecipientCandidate(
      id: 'hub_02',
      name: 'Northside Food Bank',
      organizationType: 'Food Bank',
      latitude: 13.0185,
      longitude: 77.5990,
      address: 'Northside Civic Hub, Main Sector',
      phone: '+91 98765 44332',
      beneficiaryCapacity: 250,
      acceptedCategories: ['Cooked', 'Cooked Meals', 'Produce', 'Raw Produce', 'Dairy', 'Bakery', 'Packaged', 'Packaged food', 'Food'],
      isVerified: true,
      averageResponseMinutes: 18.0,
    ),
    RecipientCandidate(
      id: 'hub_03',
      name: "Southgate Children's Shelter",
      organizationType: 'Shelter',
      latitude: 12.9330,
      longitude: 77.6050,
      address: 'Southgate Road, Near Hospital',
      phone: '+91 97412 88990',
      beneficiaryCapacity: 45,
      acceptedCategories: ['Cooked', 'Cooked Meals', 'Dairy', 'Bakery', 'Food'],
      isVerified: true,
      averageResponseMinutes: 10.0,
    ),
    RecipientCandidate(
      id: 'hub_04',
      name: 'Eastview Welfare Centre',
      organizationType: 'Welfare Centre',
      latitude: 12.9780,
      longitude: 77.6420,
      address: 'Eastview Ring Rd, 5th Block',
      phone: '+91 99001 55667',
      beneficiaryCapacity: 60,
      acceptedCategories: ['Cooked', 'Cooked Meals', 'Produce', 'Raw Produce', 'Packaged', 'Packaged food', 'Food'],
      isVerified: true,
      averageResponseMinutes: 15.0,
    ),
    RecipientCandidate(
      id: 'hub_05',
      name: 'Westlake Relief Hub',
      organizationType: 'Relief Hub',
      latitude: 12.9650,
      longitude: 77.5400,
      address: 'Westlake Lakefront Road',
      phone: '+91 94480 33221',
      beneficiaryCapacity: 180,
      acceptedCategories: ['Produce', 'Raw Produce', 'Dairy', 'Bakery', 'Packaged', 'Packaged food', 'Food'],
      isVerified: true,
      averageResponseMinutes: 20.0,
    ),
  ];

  /// 1. Haversine Formula for exact Great-Circle Geodesic Distance in km
  double calculateHaversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// 2. Estimates Urban Transit ETA in minutes (traffic heuristic)
  int estimateTravelEtaMinutes(double distanceKm) {
    // Average urban rescue transit speed ~ 22 km/h + 5 min dispatch prep
    const double averageUrbanSpeedKmh = 22.0;
    const int prepBufferMinutes = 5;

    final double driveMinutes = (distanceKm / averageUrbanSpeedKmh) * 60.0;
    return (driveMinutes + prepBufferMinutes).ceil().clamp(5, 180);
  }

  /// 3. Multi-Factor Proximity & Dispatch Ranking Algorithm
  List<ProximityMatchResult> rankNearbyRecipients({
    required double donorLat,
    required double donorLon,
    required String category,
    double? safeRemainingHours,
    int? estimatedPortions,
    List<RecipientCandidate>? customCandidates,
  }) {
    final candidates = customCandidates ?? _verifiedHubs;
    final List<ProximityMatchResult> results = [];

    // Model 3 Interlocking: Is food close to the safety danger zone?
    final bool isEmergencyPerishable =
        safeRemainingHours != null && safeRemainingHours <= 3.0;

    for (final recipient in candidates) {
      // Calculate Haversine distance
      final distanceKm = calculateHaversineDistance(
        lat1: donorLat,
        lon1: donorLon,
        lat2: recipient.latitude,
        lon2: recipient.longitude,
      );

      final etaMinutes = estimateTravelEtaMinutes(distanceKm);

      // ── Scoring Components ──
      // A. Proximity Score (Exponential distance decay, sigma = 6.0 km)
      final double distanceScore =
          100.0 * math.exp(-(distanceKm * distanceKm) / (2.0 * 6.0 * 6.0));

      // B. Category eligibility (hard rule: hub must accept category)
      final bool acceptsCategory = recipient.acceptedCategories.any((cat) =>
          cat.toLowerCase() == category.toLowerCase() ||
          cat.toLowerCase() == 'food');
      if (!acceptsCategory) continue; // Hard rule from Module 4: only eligible hubs

      // C. Determine category ID (0: Cooked, 1: Produce, 2: Dairy, 3: Bakery, 4: Packaged)
      int catId = 0;
      final catL = category.toLowerCase();
      if (catL.contains('produce') || catL.contains('raw')) {
        catId = 1;
      } else if (catL.contains('dairy') || catL.contains('milk')) {
        catId = 2;
      } else if (catL.contains('bakery') || catL.contains('bread')) {
        catId = 3;
      } else if (catL.contains('packaged')) {
        catId = 4;
      }

      final bool inTime = (etaMinutes / 60.0) + 0.25 <= (safeRemainingHours ?? 24.0);
      double? pSuccess;
      double? matchScore01;

      // 1. Run on-device TFLite neural ranker if loaded
      if (_isInitialized && _interpreter != null) {
        try {
          final input = [
            [
              distanceKm,
              etaMinutes.toDouble(),
              (estimatedPortions ?? 30).toDouble(),
              safeRemainingHours ?? 24.0,
              catId.toDouble(),
              recipient.beneficiaryCapacity.toDouble(),
            ]
          ];
          final output = List.filled(2, 0.0).reshape([1, 2]);
          _interpreter!.run(input, output);
          pSuccess = (output[0][0] as num).toDouble();
          matchScore01 = (output[0][1] as num).toDouble();
        } catch (e) {
          debugPrint('Dispatch TFLite inference fallback: $e');
        }
      }

      // 2. Analytical formula fallback if model not ready
      if (pSuccess == null || matchScore01 == null) {
        final double safeMins = (safeRemainingHours ?? 24.0) * 60.0;
        final double slack = ((safeMins - etaMinutes) / safeMins).clamp(0.0, 1.0);
        final double ratio = (estimatedPortions ?? 30) / recipient.beneficiaryCapacity;
        final double capFit = ratio <= 1.0 ? 1.0 - ((ratio - 0.5).abs() / 0.5).clamp(0.0, 1.0) : 0.0;
        final double prox = math.exp(-distanceKm / 6.0);
        matchScore01 = (0.45 * slack) + (0.30 * capFit) + (0.25 * prox);
        pSuccess = inTime ? (0.75 + 0.25 * prox) : 0.05;
      }

      // Priority formula from Module 4: priority = p_success * (0.5 + 0.5 * match_score)
      final double priority = pSuccess * (0.5 + 0.5 * matchScore01);
      final double finalScore = (priority * 100.0).clamp(10.0, 99.4);

      // Urgency Tier (from Module 4 metadata)
      String urgencyStatus = 'STANDARD';
      if ((safeRemainingHours ?? 24.0) < 2.0) {
        urgencyStatus = inTime ? 'CRITICAL DISPATCH' : 'OUT OF REACH';
      } else if ((safeRemainingHours ?? 24.0) < 3.0) {
        urgencyStatus = inTime ? 'HIGH PRIORITY' : 'OUT OF REACH';
      }

      String reason;
      if (distanceKm <= 2.5 && isEmergencyPerishable) {
        reason = 'Rapid-response hub: ETA under ${etaMinutes}m beats 2h spoilage clock.';
      } else if (distanceKm <= 3.0) {
        reason = 'High-density beneficiary shelter within 3 km.';
      } else if (acceptsCategory) {
        reason = 'Direct category match with verified food handling.';
      } else {
        reason = 'Verified distribution center in neighboring sector.';
      }

      results.add(ProximityMatchResult(
        recipient: recipient,
        distanceKm: distanceKm,
        estimatedEtaMinutes: etaMinutes,
        matchScore: double.parse(finalScore.toStringAsFixed(1)),
        urgencyStatus: urgencyStatus,
        matchReason: reason,
      ));
    }

    // Sort descending by Match Score
    results.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    // Mark the #1 candidate as optimal route
    if (results.isNotEmpty) {
      results[0] = ProximityMatchResult(
        recipient: results[0].recipient,
        distanceKm: results[0].distanceKm,
        estimatedEtaMinutes: results[0].estimatedEtaMinutes,
        matchScore: results[0].matchScore,
        urgencyStatus: results[0].urgencyStatus,
        matchReason: results[0].matchReason,
        isOptimalRoute: true,
      );
    }

    return results;
  }
}
