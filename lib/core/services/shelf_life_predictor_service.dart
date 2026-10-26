import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Storage condition chosen by the donor or inferred
enum StorageCondition {
  roomTemperature, // 25°C (standard ambient)
  refrigerated,    // 4°C (chilled)
  warmContainer,   // > 60°C (caterer thermal box)
  airtightSealed,  // Sealed dry/ambient container
}

/// Dynamic Urgency Level for NGO matching and alerts
enum UrgencyLevel {
  critical, // < 4 hours remaining (immediate dispatch needed)
  urgent,   // 4 - 12 hours remaining (same-day pickup)
  moderate, // 12 - 48 hours remaining (next-day window)
  stable,   // > 48 hours remaining (extended shelf-life)
  indefinite // Non-perishable (clothes, books, sealed cans)
}

/// Output of the Shelf-Life Prediction Engine
class ShelfLifePrediction {
  final double estimatedHoursRemaining;
  final DateTime recommendedPickupDeadline;
  final DateTime safeConsumptionExpiry;
  final UrgencyLevel urgency;
  final double confidenceScore;
  final String safetyRecommendation;
  final String optimalStorageTip;
  final bool isPerishable;
  final bool isModelInference;

  ShelfLifePrediction({
    required this.estimatedHoursRemaining,
    required this.recommendedPickupDeadline,
    required this.safeConsumptionExpiry,
    required this.urgency,
    required this.confidenceScore,
    required this.safetyRecommendation,
    required this.optimalStorageTip,
    required this.isPerishable,
    this.isModelInference = false,
  });

  Color get urgencyColor {
    switch (urgency) {
      case UrgencyLevel.critical:
        return const Color(0xFFDC2626); // Strong Red
      case UrgencyLevel.urgent:
        return const Color(0xFFEA580C); // Vibrant Orange
      case UrgencyLevel.moderate:
        return const Color(0xFFD97706); // Amber
      case UrgencyLevel.stable:
        return const Color(0xFF16A34A); // Green
      case UrgencyLevel.indefinite:
        return const Color(0xFF2563EB); // Blue
    }
  }

  String get urgencyLabel {
    switch (urgency) {
      case UrgencyLevel.critical:
        return '🚨 Critical (< 4h left)';
      case UrgencyLevel.urgent:
        return '⚡ Urgent (4-12h left)';
      case UrgencyLevel.moderate:
        return '⏳ Moderate (12-48h)';
      case UrgencyLevel.stable:
        return '🌱 Stable (> 2 days)';
      case UrgencyLevel.indefinite:
        return '📦 Non-Perishable';
    }
  }

  String get formattedRemainingTime {
    if (!isPerishable || urgency == UrgencyLevel.indefinite) {
      return 'Long shelf-life';
    }
    final totalMins = (estimatedHoursRemaining * 60).toInt();
    final hours = totalMins ~/ 60;
    final mins = totalMins % 60;
    if (hours > 24) {
      final days = (hours / 24).toStringAsFixed(1);
      return '$days days left';
    }
    return '${hours}h ${mins}m left';
  }
}

/// HarvestHub Hybrid Shelf-Life Engine:
/// 1. TFLite Deep Neural Network Regressor (trained on Kaggle)
/// 2. Deterministic USDA / FDA Food-Safety Regulatory Guardrails
class ShelfLifePredictorService {
  static final ShelfLifePredictorService _instance =
      ShelfLifePredictorService._internal();
  factory ShelfLifePredictorService() => _instance;
  ShelfLifePredictorService._internal();

  Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _interpreter = await Interpreter.fromAsset(
          'assets/ml/harvest_hub_shelf_life_model.tflite');
      _isInitialized = true;
      debugPrint('ShelfLifePredictorService: TFLite model loaded successfully.');
      return true;
    } catch (e) {
      debugPrint('ShelfLifePredictorService: TFLite load error: $e');
      return false;
    }
  }

  /// Predicts shelf-life and decay window based on item parameters
  ShelfLifePrediction predictShelfLife({
    required String category,
    String? specificItemName,
    DateTime? preparedAt,
    StorageCondition storage = StorageCondition.roomTemperature,
    bool isAirtight = false,
    bool? isVisuallyFresh,
  }) {
    final now = DateTime.now();
    final cookingTime = preparedAt ?? now;
    final elapsedHours = (now.difference(cookingTime).inMinutes / 60.0).clamp(0.0, 48.0);

    final catLower = category.toLowerCase();
    final itemLower = (specificItemName ?? '').toLowerCase();

    // Check if non-perishable
    if (catLower == 'clothes' ||
        catLower == 'books' ||
        catLower == 'electronics' ||
        catLower == 'furniture') {
      return ShelfLifePrediction(
        estimatedHoursRemaining: 8760,
        recommendedPickupDeadline: now.add(const Duration(days: 30)),
        safeConsumptionExpiry: now.add(const Duration(days: 365)),
        urgency: UrgencyLevel.indefinite,
        confidenceScore: 0.99,
        safetyRecommendation: 'Safe indefinitely under clean, dry conditions.',
        optimalStorageTip: 'Store away from moisture and direct sunlight.',
        isPerishable: false,
      );
    }

    // Map Category to Model ID
    // 0: Cooked meals, 1: Raw produce, 2: Dairy, 3: Bakery, 4: Packaged food
    int categoryId = 0;
    if (itemLower.contains('milk') || itemLower.contains('curd') || itemLower.contains('dairy')) {
      categoryId = 2;
    } else if (catLower.contains('produce') || catLower.contains('raw')) {
      categoryId = 1;
    } else if (catLower.contains('bakery') || itemLower.contains('bread')) {
      categoryId = 3;
    } else if (catLower.contains('packaged')) {
      categoryId = 4;
    } else {
      categoryId = 0; // Default cooked meals
    }

    // Storage Temperature in Celsius
    double tempC = 25.0;
    if (storage == StorageCondition.refrigerated) {
      tempC = 4.0;
    } else if (storage == StorageCondition.warmContainer) {
      tempC = 62.0;
    }

    final bool airtightFlag = isAirtight || storage == StorageCondition.airtightSealed;
    final double visionScore = isVisuallyFresh == true
        ? 0.95
        : (isVisuallyFresh == false ? 0.15 : 0.90);

    // 1. Run TFLite Neural Network Inference if available
    double? modelHours;
    if (_isInitialized && _interpreter != null) {
      try {
        final input = [
          [
            categoryId.toDouble(),
            tempC,
            airtightFlag ? 1.0 : 0.0,
            elapsedHours,
            visionScore,
          ]
        ];
        final output = List.filled(1, 0.0).reshape([1, 1]);
        _interpreter!.run(input, output);
        modelHours = (output[0][0] as num).toDouble();
      } catch (e) {
        debugPrint('TFLite inference error, using analytical formula: $e');
      }
    }

    // 2. Fallback to Food Science Formula if model not loaded yet
    if (modelHours == null) {
      final baseHours = [48.0, 120.0, 72.0, 96.0, 720.0][categoryId];
      final tempMultiplier = storage == StorageCondition.refrigerated ? 3.5 : 1.0;
      final qualMultiplier = isVisuallyFresh == false ? 0.25 : 1.0;
      modelHours = (baseHours * tempMultiplier * qualMultiplier) - elapsedHours;
    }

    // 3. FDA / USDA Danger-Zone Safety Guard (Deterministic rules always override ML)
    double remainingHours = modelHours * 0.85; // 15% safety margin
    if (visionScore < 0.40) {
      remainingHours = 0.0; // Visually spoiled -> 0h
    } else if ((categoryId == 0 || categoryId == 2) && tempC > 5.0 && tempC < 60.0) {
      // TCS food in 5°C - 60°C danger zone: USDA rule: max 2 hours (1h if hot day)
      final cap = tempC >= 32.2 ? 1.0 : 2.0;
      final maxRemaining = (cap - elapsedHours).clamp(0.0, cap);
      if (remainingHours > maxRemaining) remainingHours = maxRemaining;
    }
    remainingHours = remainingHours.clamp(0.0, 720.0);

    // 4. Determine Urgency Level
    UrgencyLevel urgency;
    if (remainingHours <= 4.0) {
      urgency = UrgencyLevel.critical;
    } else if (remainingHours <= 12.0) {
      urgency = UrgencyLevel.urgent;
    } else if (remainingHours <= 48.0) {
      urgency = UrgencyLevel.moderate;
    } else {
      urgency = UrgencyLevel.stable;
    }

    final pickupDeadline = now.add(Duration(minutes: (remainingHours * 0.70 * 60).toInt()));
    final safeExpiry = now.add(Duration(minutes: (remainingHours * 60).toInt()));

    final advice = _generateStorageTips(categoryId, storage, remainingHours);

    return ShelfLifePrediction(
      estimatedHoursRemaining: remainingHours,
      recommendedPickupDeadline: pickupDeadline,
      safeConsumptionExpiry: safeExpiry,
      urgency: urgency,
      confidenceScore: _isInitialized ? 0.98 : 0.92,
      safetyRecommendation: advice['safety']!,
      optimalStorageTip: advice['storage']!,
      isPerishable: true,
      isModelInference: _isInitialized,
    );
  }

  Map<String, String> _generateStorageTips(
    int categoryId,
    StorageCondition currentStorage,
    double remainingHours,
  ) {
    if (currentStorage != StorageCondition.refrigerated && remainingHours <= 4.0) {
      return {
        'safety': 'USDA Alert: TCS food in danger zone (> 5°C) bacterial growth accelerates.',
        'storage': '💡 Chill below 4°C immediately to extend pickup window by +12 to 18 hours.',
      };
    } else if (currentStorage == StorageCondition.refrigerated) {
      return {
        'safety': 'Cold chain active. Microbial reproduction safely arrested.',
        'storage': 'Maintain sealed lid to avoid condensation and cross-contamination.',
      };
    } else {
      return {
        'safety': 'Safe consumption window estimated based on storage conditions.',
        'storage': 'Keep containers tightly covered and shaded from heat.',
      };
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
