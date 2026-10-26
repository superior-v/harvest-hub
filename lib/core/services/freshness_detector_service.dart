import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FreshnessResult {
  final String rawLabel;
  final String fruitType;
  final bool isSpoiled;
  final double confidence;
  final String statusTitle;
  final String statusDescription;

  FreshnessResult({
    required this.rawLabel,
    required this.fruitType,
    required this.isSpoiled,
    required this.confidence,
    required this.statusTitle,
    required this.statusDescription,
  });

  bool get isHighConfidence => confidence >= 0.75;
}

class FreshnessDetectorService {
  static final FreshnessDetectorService _instance = FreshnessDetectorService._internal();
  factory FreshnessDetectorService() => _instance;
  FreshnessDetectorService._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // 1. Load Labels
      final labelsRaw = await rootBundle.loadString('assets/ml/freshness_labels.txt');
      _labels = labelsRaw
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // 2. Load TFLite Model
      _interpreter = await Interpreter.fromAsset('assets/ml/harvest_hub_freshness_model.tflite');
      _isInitialized = true;
      debugPrint('FreshnessDetectorService loaded with ${_labels.length} classes.');
      return true;
    } catch (e) {
      debugPrint('Error initializing FreshnessDetectorService: $e');
      return false;
    }
  }

  /// Evaluates freshness for a produce image
  Future<FreshnessResult?> analyzeFreshness(File imageFile) async {
    try {
      if (!_isInitialized) {
        final ok = await initialize();
        if (!ok || _interpreter == null) return null;
      }

      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final resized = img.copyResize(decoded, width: 224, height: 224);

      // Raw 0-255 float32 input (model has internal Rescaling layer)
      final input = List.generate(
        1,
        (b) => List.generate(
          224,
          (y) => List.generate(
            224,
            (x) {
              final pixel = resized.getPixel(x, y);
              return [
                pixel.r.toDouble(),
                pixel.g.toDouble(),
                pixel.b.toDouble(),
              ];
            },
          ),
        ),
      );

      final outShape = _interpreter!.getOutputTensor(0).shape;
      final outLength = outShape.last;
      final output = List.filled(1 * outLength, 0.0).reshape([1, outLength]);
      _interpreter!.run(input, output);

      final probabilities = List<double>.from(output[0]);
      int maxIdx = 0;
      double maxProb = 0.0;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIdx = i;
        }
      }

      final label = (maxIdx < _labels.length) ? _labels[maxIdx] : 'unknown';
      debugPrint('FreshnessDetector: label=$label confidence=${(maxProb * 100).toStringAsFixed(1)}%');
      final isSpoiled = label.toLowerCase().startsWith('rotten');

      String fruit = 'Produce';
      if (label.contains('apple')) fruit = 'Apple';
      if (label.contains('banana')) fruit = 'Banana';
      if (label.contains('orange')) fruit = 'Orange';

      final title = isSpoiled ? '⚠️ Spoilage Warning' : '✅ Fresh Quality Verified';
      final desc = isSpoiled
          ? 'Visible mold or decay detected ($fruit). Unfit for donation.'
          : 'High quality produce ($fruit). Safe for immediate distribution.';

      return FreshnessResult(
        rawLabel: label,
        fruitType: fruit,
        isSpoiled: isSpoiled,
        confidence: maxProb,
        statusTitle: title,
        statusDescription: desc,
      );
    } catch (e) {
      debugPrint('Freshness analysis error: $e');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
