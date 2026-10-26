import 'dart:async';
import 'package:flutter/material.dart';
import 'package:harvest/core/services/shelf_life_predictor_service.dart';

/// Interactive UI Card displaying dynamic AI Shelf-Life Prediction,
/// storage condition selectors, and real-time decay countdown.
class ShelfLifeForecastCard extends StatefulWidget {
  final ShelfLifePrediction prediction;
  final StorageCondition selectedStorage;
  final ValueChanged<StorageCondition> onStorageChanged;
  final VoidCallback? onApplyDeadlineToForm;

  const ShelfLifeForecastCard({
    super.key,
    required this.prediction,
    required this.selectedStorage,
    required this.onStorageChanged,
    this.onApplyDeadlineToForm,
  });

  @override
  State<ShelfLifeForecastCard> createState() => _ShelfLifeForecastCardState();
}

class _ShelfLifeForecastCardState extends State<ShelfLifeForecastCard> {
  Timer? _ticker;
  late Duration _remainingDuration;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final diff = widget.prediction.safeConsumptionExpiry.difference(now);
    if (mounted) {
      setState(() {
        _remainingDuration = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ShelfLifeForecastCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prediction.safeConsumptionExpiry !=
        widget.prediction.safeConsumptionExpiry) {
      _updateRemaining();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatTimer() {
    if (!widget.prediction.isPerishable) return 'Indefinite';
    final hours = _remainingDuration.inHours;
    final minutes = _remainingDuration.inMinutes % 60;
    final seconds = _remainingDuration.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}h : ${minutes.toString().padLeft(2, '0')}m : ${seconds.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final pred = widget.prediction;
    final isCritical = pred.urgency == UrgencyLevel.critical;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: pred.urgencyColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: pred.urgencyColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: pred.urgencyColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCritical ? Icons.timer_off_rounded : Icons.hourglass_top_rounded,
                  color: pred.urgencyColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Dynamic Shelf-Life Engine',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A3A1F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Decay prediction (USDA / WHO standards)',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF6B7A6E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pred.urgencyColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pred.urgencyLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Live Countdown Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: pred.urgencyColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pred.urgencyColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SAFE CONSUMPTION WINDOW',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Color(0xFF6B7A6E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatTimer(),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: pred.urgencyColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'DEADLINE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Color(0xFF6B7A6E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${pred.recommendedPickupDeadline.hour.toString().padLeft(2, '0')}:${pred.recommendedPickupDeadline.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F1F12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Interactive Storage Condition Selector
          const Text(
            'Current Storage Condition (Affects Decay Rate):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F1F12)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStorageChip(
                  label: 'Room Temp (25°C)',
                  icon: Icons.wb_sunny_outlined,
                  value: StorageCondition.roomTemperature,
                ),
                const SizedBox(width: 8),
                _buildStorageChip(
                  label: 'Refrigerated (< 4°C)',
                  icon: Icons.ac_unit_rounded,
                  value: StorageCondition.refrigerated,
                ),
                const SizedBox(width: 8),
                _buildStorageChip(
                  label: 'Airtight Sealed',
                  icon: Icons.lock_outline_rounded,
                  value: StorageCondition.airtightSealed,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Storage Tip Advice
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFF3D7A45)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pred.optimalStorageTip,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF1A3A1F), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageChip({
    required String label,
    required IconData icon,
    required StorageCondition value,
  }) {
    final isSelected = widget.selectedStorage == value;
    return GestureDetector(
      onTap: () => widget.onStorageChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A3A1F) : const Color(0xFFF3F7F0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A3A1F) : const Color(0xFFDEEADE),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF6B7A6E),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF0F1F12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
