import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:harvest/core/services/proximity_matching_service.dart';

/// Interactive UI Card displaying AI Proximity-Matched NGOs & Shelters
class ProximityMatchedNgosCard extends StatelessWidget {
  final List<ProximityMatchResult> matches;
  final ValueChanged<RecipientCandidate>? onSelectRecipient;

  const ProximityMatchedNgosCard({
    super.key,
    required this.matches,
    this.onSelectRecipient,
  });

  static const Color _forest = Color(0xFF1A3A1F);
  static const Color _leaf = Color(0xFF3D7A45);
  static const Color _sprout = Color(0xFF6BBF6A);
  static const Color _mist = Color(0xFFF3F7F0);
  static const Color _divider = Color(0xFFDEEADE);
  static const Color _ink = Color(0xFF0F1F12);
  static const Color _slate = Color(0xFF6B7A6E);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    final topMatches = matches.take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _sprout.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _leaf.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.radar_rounded, color: _leaf, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Proximity Match Engine',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _forest,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Geodesic distance & urgency-ranked dispatch',
                      style: TextStyle(fontSize: 11, color: _slate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _forest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${matches.length} Nearby Hubs',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Match Candidate Cards
          ...topMatches.asMap().entries.map((entry) {
            final index = entry.key;
            final match = entry.value;
            final isTop = index == 0;

            return Container(
              margin: EdgeInsets.only(bottom: index == topMatches.length - 1 ? 0 : 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isTop ? _mist : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isTop ? _leaf : _divider,
                  width: isTop ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Badge Score
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isTop ? _leaf : _slate,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${match.matchScore.toStringAsFixed(0)}% Match',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isTop)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade700, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: 12, color: Colors.amber.shade900),
                              const SizedBox(width: 3),
                              Text(
                                'Optimal Route',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (match.urgencyStatus == 'CRITICAL DISPATCH')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '⚡ Rapid Dispatch',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Name & Type
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.recipient.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${match.recipient.organizationType} • Feeds ${match.recipient.beneficiaryCapacity}+ people',
                              style: const TextStyle(fontSize: 11.5, color: _slate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Distance, ETA & Actions
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.near_me_rounded, size: 12, color: _leaf),
                            const SizedBox(width: 3),
                            Text(
                              match.formattedDistance,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _forest),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.directions_car_rounded, size: 12, color: _slate),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                match.formattedEta,
                                style: const TextStyle(fontSize: 11, color: _slate),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Phone Call Button
                      IconButton(
                        onPressed: () => _makePhoneCall(match.recipient.phone),
                        icon: const Icon(Icons.phone_outlined, size: 18, color: _leaf),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Call Hub',
                      ),
                      const SizedBox(width: 4),

                      // Select / Dispatch Button
                      ElevatedButton(
                        onPressed: () {
                          if (onSelectRecipient != null) {
                            onSelectRecipient!(match.recipient);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📍 Priority Dispatch requested to ${match.recipient.name}'),
                              backgroundColor: _leaf,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTop ? _leaf : _forest,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          isTop ? 'Direct Alert' : 'Select',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
