import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ClassificationResult {
  final String itemName;
  final String category;
  final bool isPerishable;
  final double confidence;
  final String estimatedShelfLife;
  final String rawLabel;

  ClassificationResult({
    required this.itemName,
    required this.category,
    required this.isPerishable,
    required this.confidence,
    required this.estimatedShelfLife,
    required this.rawLabel,
  });

  @override
  String toString() =>
      '$itemName ($category, ${(confidence * 100).toStringAsFixed(1)}%) - Perishable: $isPerishable';
}

class ItemClassifierService {
  static final ItemClassifierService _instance = ItemClassifierService._internal();
  factory ItemClassifierService() => _instance;
  ItemClassifierService._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Load TFLite model and labels from assets
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // 1. Load Labels
      final labelData = await rootBundle.loadString('assets/ml/labels.txt');
      _labels = labelData
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      // 2. Load Interpreter
      _interpreter = await Interpreter.fromAsset('assets/ml/donation_classifier.tflite');
      _isInitialized = true;
      debugPrint('ItemClassifierService initialized with ${_labels.length} labels.');
      return true;
    } catch (e) {
      debugPrint('ItemClassifierService init error: $e');
      return false;
    }
  }

  /// Classifies a picked image file
  Future<ClassificationResult?> classifyImage(File imageFile) async {
    try {
      if (!_isInitialized) {
        final success = await initialize();
        if (!success || _interpreter == null) return null;
      }

      // 1. Read & decode image
      final bytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return null;

      // 2. Resize to 224x224 (MobileNet standard input)
      final resizedImage = img.copyResize(decodedImage, width: 224, height: 224);

      // 3. Normalize input to float32 [-1, 1] for MobileNetV2
      final input = List.generate(
        1,
        (b) => List.generate(
          224,
          (y) => List.generate(
            224,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              return [
                (pixel.r / 127.5) - 1.0,
                (pixel.g / 127.5) - 1.0,
                (pixel.b / 127.5) - 1.0,
              ];
            },
          ),
        ),
      );

      // 4. Output buffer dynamically sized to model's tensor
      final outShape = _interpreter!.getOutputTensor(0).shape;
      final outLength = outShape.last;
      final output = List.filled(1 * outLength, 0.0).reshape([1, outLength]);

      // 5. Run Inference
      _interpreter!.run(input, output);

      // 6. Extract top prediction
      final probabilities = List<double>.from(output[0]);
      int maxIdx = 0;
      double maxScore = 0.0;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxScore) {
          maxScore = probabilities[i];
          maxIdx = i;
        }
      }

      final rawLabel = (maxIdx < _labels.length) ? _labels[maxIdx] : 'Unknown';
      debugPrint('ItemClassifier: Top item="$rawLabel" confidence=${(maxScore * 100).toStringAsFixed(1)}%');

      // 7. Map ImageNet item to HarvestHub Donation Categories
      return _mapLabelToDonationCategory(rawLabel, maxScore);
    } catch (e) {
      debugPrint('Error during classification: $e');
      return null;
    }
  }

  /// Maps specific items (e.g. 'Granny Smith', 'French loaf', 'jersey')
  /// into HarvestHub's standard categories and shelf-life estimations.
  ClassificationResult _mapLabelToDonationCategory(String raw, double confidence) {
    final lower = raw.toLowerCase();

    // 1. Fresh Produce (Raw Produce)
    if (_isFreshProduce(lower)) {
      return ClassificationResult(
        itemName: _cleanItemName(raw),
        category: 'Raw Produce',
        isPerishable: true,
        confidence: confidence,
        estimatedShelfLife: '3 - 5 days',
        rawLabel: raw,
      );
    }

    // 2. Cooked Meals
    if (_isCookedMeal(lower)) {
      return ClassificationResult(
        itemName: _cleanItemName(raw),
        category: 'Cooked Meals',
        isPerishable: true,
        confidence: confidence,
        estimatedShelfLife: '12 - 24 hours',
        rawLabel: raw,
      );
    }

    // 3. Packaged Food / General Food
    if (_isGeneralFood(lower)) {
      return ClassificationResult(
        itemName: _cleanItemName(raw),
        category: 'Food',
        isPerishable: true,
        confidence: confidence,
        estimatedShelfLife: '2 - 4 days',
        rawLabel: raw,
      );
    }

    // 4. Clothes / Wearables
    if (_isClothing(lower)) {
      return ClassificationResult(
        itemName: _cleanItemName(raw),
        category: 'Clothes',
        isPerishable: false,
        confidence: confidence,
        estimatedShelfLife: 'Non-Perishable',
        rawLabel: raw,
      );
    }

    // 5. Books / Paper
    if (_isBooks(lower)) {
      return ClassificationResult(
        itemName: _cleanItemName(raw),
        category: 'Books',
        isPerishable: false,
        confidence: confidence,
        estimatedShelfLife: 'Non-Perishable',
        rawLabel: raw,
      );
    }

    // Default Fallback
    return ClassificationResult(
      itemName: _cleanItemName(raw),
      category: 'Other',
      isPerishable: false,
      confidence: confidence,
      estimatedShelfLife: 'Verify on inspection',
      rawLabel: raw,
    );
  }

  bool _isFreshProduce(String l) {
    const list = [
      'apple', 'banana', 'orange', 'lemon', 'fig', 'pineapple', 'strawberry',
      'jackfruit', 'custard apple', 'pomegranate', 'cabbage', 'broccoli',
      'cauliflower', 'zucchini', 'squash', 'cucumber', 'artichoke', 'bell pepper',
      'mushroom', 'corn', 'acorn', 'rapeseed', 'produce', 'vegetable', 'fruit',
      'tomato', 'potato'
    ];
    return list.any((item) => l.contains(item));
  }

  bool _isCookedMeal(String l) {
    const list = [
      'cheeseburger', 'hotdog', 'pizza', 'potpie', 'burrito', 'meat loaf',
      'carbonara', 'bagel', 'french loaf', 'pretzel', 'mashed potato',
      'soup', 'noodle', 'curry', 'rice', 'sandwich', 'pasta', 'stew'
    ];
    return list.any((item) => l.contains(item));
  }

  bool _isGeneralFood(String l) {
    const list = [
      'ice cream', 'ice lolly', 'chocolate', 'dough', 'eggnog', 'espresso',
      'cup', 'bottle', 'can', 'bread', 'food', 'snack'
    ];
    return list.any((item) => l.contains(item));
  }

  bool _isClothing(String l) {
    const list = [
      'jersey', 'jean', 'sweater', 'sweatshirt', 'cardigan', 'coat',
      'jacket', 'suit', 'dress', 'shirt', 'vest', 'trench coat',
      'sock', 'shoe', 'boot', 'sandal', 'hat', 'cap', 'apron'
    ];
    return list.any((item) => l.contains(item));
  }

  bool _isBooks(String l) {
    const list = ['book', 'book jacket', 'notebook', 'comic', 'paper', 'binder'];
    return list.any((item) => l.contains(item));
  }

  String _cleanItemName(String raw) {
    if (raw.isEmpty || raw.toLowerCase() == 'background') return 'Item';
    // Format "granny smith" -> "Granny Smith"
    final words = raw.split(' ');
    return words
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
