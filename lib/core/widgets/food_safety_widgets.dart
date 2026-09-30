import 'dart:async';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

class DietaryTag {
  static const String veg = 'Veg';
  static const String nonVeg = 'Non-Veg';
  static const String vegan = 'Vegan';
  static const String halal = 'Halal';
  static const String jain = 'Jain';

  static const List<String> all = [veg, nonVeg, vegan, halal, jain];

  static Color colorFor(String tag) {
    switch (tag) {
      case veg:
        return const Color(0xFF2E7D32);
      case nonVeg:
        return const Color(0xFFC62828);
      case vegan:
        return const Color(0xFF558B2F);
      case halal:
        return const Color(0xFF1565C0);
      case jain:
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF546E7A);
    }
  }

  static IconData iconFor(String tag) {
    switch (tag) {
      case veg:
        return Icons.eco_rounded;
      case nonVeg:
        return Icons.set_meal_rounded;
      case vegan:
        return Icons.grass_rounded;
      case halal:
        return Icons.verified_rounded;
      case jain:
        return Icons.spa_rounded;
      default:
        return Icons.label_rounded;
    }
  }
}

class AllergenTag {
  static const String nuts = 'Nuts';
  static const String dairy = 'Dairy';
  static const String gluten = 'Gluten';
  static const String eggs = 'Eggs';
  static const String soy = 'Soy';
  static const String shellfish = 'Shellfish';

  static const List<String> all = [nuts, dairy, gluten, eggs, soy, shellfish];

  static String emojiFor(String tag) {
    switch (tag) {
      case nuts:
        return '🥜';
      case dairy:
        return '🥛';
      case gluten:
        return '🌾';
      case eggs:
        return '🥚';
      case soy:
        return '🫘';
      case shellfish:
        return '🦐';
      default:
        return '⚠️';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PERISHABILITY COUNTDOWN BADGE
// Live ticking countdown: color transitions green → amber → red
// ─────────────────────────────────────────────────────────────────────────────

class PerishabilityBadge extends StatefulWidget {
  final DateTime? pickupDeadline;
  final bool compact;

  const PerishabilityBadge({
    Key? key,
    required this.pickupDeadline,
    this.compact = false,
  }) : super(key: key);

  @override
  State<PerishabilityBadge> createState() => _PerishabilityBadgeState();
}

class _PerishabilityBadgeState extends State<PerishabilityBadge>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    if (widget.pickupDeadline == null) return;
    setState(() {
      _remaining = widget.pickupDeadline!.difference(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Returns a color based on how much time is left.
  Color get _urgencyColor {
    if (_remaining.isNegative) return const Color(0xFF9E9E9E); // expired grey
    final hours = _remaining.inHours;
    if (hours <= 1) return const Color(0xFFD32F2F); // urgent red
    if (hours <= 3) return const Color(0xFFF57C00); // amber
    if (hours <= 12) return const Color(0xFFF9A825); // yellow
    return const Color(0xFF388E3C); // safe green
  }

  Color get _bgColor => _urgencyColor.withValues(alpha: 0.12);

  String get _label {
    if (widget.pickupDeadline == null) return '';
    if (_remaining.isNegative) return 'Expired';
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    if (h > 24) {
      final days = _remaining.inDays;
      return 'Expires in ${days}d';
    }
    if (h > 0) return 'Pickup within ${h}h ${m}m';
    if (m > 0) return 'Pickup in ${m}m!';
    return 'Expires soon!';
  }

  bool get _isUrgent => !_remaining.isNegative && _remaining.inHours <= 1;

  @override
  Widget build(BuildContext context) {
    if (widget.pickupDeadline == null) return const SizedBox.shrink();

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 7 : 10,
        vertical: widget.compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _urgencyColor.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _remaining.isNegative
                ? Icons.block_rounded
                : _isUrgent
                    ? Icons.timer_off_rounded
                    : Icons.timer_rounded,
            size: widget.compact ? 10 : 12,
            color: _urgencyColor,
          ),
          SizedBox(width: widget.compact ? 3 : 4),
          Text(
            _label,
            style: TextStyle(
              fontSize: widget.compact ? 9 : 10.5,
              fontWeight: FontWeight.w700,
              color: _urgencyColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );

    if (_isUrgent) {
      return ScaleTransition(scale: _pulseAnimation, child: badge);
    }
    return badge;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIETARY TAG DISPLAY ROW
// ─────────────────────────────────────────────────────────────────────────────

class DietaryTagsRow extends StatelessWidget {
  final List<String> tags;
  final bool compact;

  const DietaryTagsRow({Key? key, required this.tags, this.compact = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.map((tag) {
        final color = DietaryTag.colorFor(tag);
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 9,
            vertical: compact ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(DietaryTag.iconFor(tag),
                  size: compact ? 9 : 11, color: color),
              SizedBox(width: compact ? 3 : 4),
              Text(
                tag,
                style: TextStyle(
                  fontSize: compact ? 9 : 10.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALLERGEN TAGS ROW
// ─────────────────────────────────────────────────────────────────────────────

class AllergenTagsRow extends StatelessWidget {
  final List<String> tags;
  final bool compact;

  const AllergenTagsRow({Key? key, required this.tags, this.compact = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: tags.map((tag) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFFE65100).withValues(alpha: 0.35), width: 1),
          ),
          child: Text(
            '${AllergenTag.emojiFor(tag)} $tag',
            style: TextStyle(
              fontSize: compact ? 9 : 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFBF360C),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SELECTOR CHIPS for Post Donation Screen
// ─────────────────────────────────────────────────────────────────────────────

class MultiSelectChips extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final Color activeColor;

  const MultiSelectChips({
    Key? key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.activeColor = const Color(0xFF3D7A45),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return GestureDetector(
          onTap: () => onToggle(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.12)
                  : const Color(0xFFF3F7F0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? activeColor
                    : const Color(0xFFDEEADE),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : Colors.black54,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
