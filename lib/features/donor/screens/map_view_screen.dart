import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:harvest/core/services/map_service.dart';
import 'package:harvest/core/services/firestore_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class CategoryConfig {
  final String emoji;
  final Color color;
  final String label;

  const CategoryConfig({
    required this.emoji,
    required this.color,
    required this.label,
  });
}

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  // Theme Tokens
  static const Color _forest = Color(0xFF1A3A1F);
  static const Color _leaf = Color(0xFF3D7A45);
  static const Color _sprout = Color(0xFF6BBF6A);
  static const Color _mist = Color(0xFFF3F7F0);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF0F1F12);
  static const Color _slate = Color(0xFF6B7A6E);
  static const Color _divider = Color(0xFFDEEADE);

  static const LinearGradient _heroGradient = LinearGradient(
    colors: [Color(0xFF1A3A1F), Color(0xFF2D5E33)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  GoogleMapController? _mapController;
  final MapService _mapService = MapService();
  final FirestoreService _firestoreService = FirestoreService();

  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final List<Map<String, dynamic>> _rawDonations = [];
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  Set<String> _userRequestedDonationIds = {};

  bool _isLoading = true;
  bool _isFarmer = false;
  String _selectedFilter = 'All';

  // Selected donation for the interactive bottom sheet preview card
  Map<String, dynamic>? _selectedDonation;
  String? _selectedDonationId;

  // Default fallback center location (India center)
  static const LatLng _defaultLocation = LatLng(20.5937, 78.9629);

  final List<String> _filterCategories = [
    'All',
    'Food',
    'Raw Produce',
    'Cooked Meals',
    'Clothes',
    'Organic Waste',
    'Medicine',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _checkUserRole();
    await _getCurrentLocation();
    await _loadUserRequests();
    await _loadDonations();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final requestsSnap = await FirebaseFirestore.instance
            .collection('requests')
            .where('recipientId', isEqualTo: user.uid)
            .where('status', whereIn: ['pending', 'approved', 'accepted'])
            .get();

        _userRequestedDonationIds = requestsSnap.docs
            .map((d) => (d.data()['donationId'] as String? ?? ''))
            .where((id) => id.isNotEmpty)
            .toSet();
      } catch (e) {
        debugPrint('Error loading user requests: $e');
      }
    }
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['role'] == 'farmer') {
            _isFarmer = true;
          }
        }
      } catch (e) {
        debugPrint('Error checking user role: $e');
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await _mapService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ),
      );
    }
  }

  static CategoryConfig getCategoryConfig(String category) {
    final lower = category.toLowerCase().trim();
    if (lower.contains('raw') ||
        lower.contains('produce') ||
        lower.contains('vegetable') ||
        lower.contains('fruit') ||
        lower.contains('fresh')) {
      return const CategoryConfig(
        emoji: '🥦',
        color: Color(0xFF2E7D32),
        label: 'Raw Produce',
      );
    } else if (lower.contains('cooked') ||
        lower.contains('meal') ||
        lower.contains('curry') ||
        lower.contains('rice') ||
        lower.contains('hot') ||
        lower.contains('prepared')) {
      return const CategoryConfig(
        emoji: '🍲',
        color: Color(0xFFD84315),
        label: 'Cooked Meals',
      );
    } else if (lower.contains('food') ||
        lower.contains('bakery') ||
        lower.contains('bread') ||
        lower.contains('canned') ||
        lower.contains('grocery') ||
        lower.contains('grain')) {
      return const CategoryConfig(
        emoji: '🥖',
        color: Color(0xFFE65100),
        label: 'Food & Bakery',
      );
    } else if (lower.contains('cloth') ||
        lower.contains('wear') ||
        lower.contains('apparel') ||
        lower.contains('shirt') ||
        lower.contains('dress')) {
      return const CategoryConfig(
        emoji: '👕',
        color: Color(0xFF1565C0),
        label: 'Clothing',
      );
    } else if (lower.contains('waste') ||
        lower.contains('manure') ||
        lower.contains('seed') ||
        lower.contains('farm') ||
        lower.contains('organic')) {
      return const CategoryConfig(
        emoji: '🌾',
        color: Color(0xFF558B2F),
        label: 'Farm & Organic',
      );
    } else if (lower.contains('med') ||
        lower.contains('health') ||
        lower.contains('pharma') ||
        lower.contains('tablet')) {
      return const CategoryConfig(
        emoji: '💊',
        color: Color(0xFFC62828),
        label: 'Medicine',
      );
    } else {
      return const CategoryConfig(
        emoji: '📦',
        color: Color(0xFF6A1B9A),
        label: 'Other',
      );
    }
  }

  Future<BitmapDescriptor> _getCategoryMarker(String category, {bool isSelected = false}) async {
    final cacheKey = '${category}_$isSelected';
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }

    final config = getCategoryConfig(category);
    final descriptor = await _createCustomPinBitmap(
      emoji: config.emoji,
      bgColor: config.color,
      isSelected: isSelected,
    );
    _markerIconCache[cacheKey] = descriptor;
    return descriptor;
  }

  Future<BitmapDescriptor> _createCustomPinBitmap({
    required String emoji,
    required Color bgColor,
    bool isSelected = false,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double width = 110.0;
    const double height = 135.0;
    final double radius = isSelected ? 42.0 : 36.0;

    // Draw soft drop shadow under the pin
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(const Offset(width / 2, 44), radius + 2, shadowPaint);

    // Draw Pin pointer (triangle pointing to coordinates)
    final Path pinPath = Path();
    pinPath.moveTo((width / 2) - 14, 60);
    pinPath.lineTo(width / 2, height - 10);
    pinPath.lineTo((width / 2) + 14, 60);
    pinPath.close();

    final Paint pointerPaint = Paint()
      ..color = isSelected ? const Color(0xFF0F1F12) : bgColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, pointerPaint);

    // Draw outer circle
    final Paint outerPaint = Paint()
      ..color = isSelected ? const Color(0xFF0F1F12) : bgColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(width / 2, 44), radius, outerPaint);

    // Draw outer white ring border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 4.0 : 3.0;
    canvas.drawCircle(const Offset(width / 2, 44), radius - 1, borderPaint);

    // Draw inner white disc for emoji clarity
    final Paint innerCirclePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      const Offset(width / 2, 44),
      radius - (isSelected ? 7 : 6),
      innerCirclePaint,
    );

    // Draw Emoji in the center
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.text = TextSpan(
      text: emoji,
      style: TextStyle(
        fontSize: isSelected ? 32.0 : 26.0,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        44 - (textPainter.height / 2),
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
          width.toInt(),
          height.toInt(),
        );
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  Future<void> _loadDonations() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('status', isEqualTo: 'available')
          .get();

      _rawDonations.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        _rawDonations.add(data);
      }

      await _rebuildMarkers();
    } catch (e) {
      debugPrint('Error loading donations for map: $e');
    }
  }

  Future<void> _rebuildMarkers() async {
    final Set<Marker> newMarkers = {};

    // Current location marker
    if (_currentPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_user_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: '📍 Your Location'),
        ),
      );
    }

    final farmerCategories = ['Organic Waste', 'Manure', 'Seeds'];

    for (var data in _rawDonations) {
      final lat = (data['latitude'] as num?)?.toDouble();
      final lon = (data['longitude'] as num?)?.toDouble();
      final category = data['category'] as String? ?? 'Other';
      final donationId = data['id'] as String;

      // Role and category filter checks
      if (_isFarmer) {
        if (!farmerCategories.contains(category)) continue;
      } else {
        if (farmerCategories.contains(category)) continue;
      }

      if (_selectedFilter != 'All') {
        final config = getCategoryConfig(category);
        if (_selectedFilter != config.label && _selectedFilter != category) {
          continue;
        }
      }

      if (lat != null && lon != null) {
        final isSelected = _selectedDonationId == donationId;
        final icon = await _getCategoryMarker(category, isSelected: isSelected);

        newMarkers.add(
          Marker(
            markerId: MarkerId(donationId),
            position: LatLng(lat, lon),
            icon: icon,
            zIndexInt: isSelected ? 2 : 1,
            onTap: () {
              _onMarkerTapped(donationId, data, lat, lon);
            },
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _markers
          ..clear()
          ..addAll(newMarkers);
      });
    }
  }

  void _onMarkerTapped(String donationId, Map<String, dynamic> data, double lat, double lon) {
    setState(() {
      _selectedDonationId = donationId;
      _selectedDonation = data;
    });

    // Rebuild markers to highlight the selected pin
    _rebuildMarkers();

    // Pan camera slightly lower so bottom preview card doesn't obscure the marker pin
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(lat - 0.003, lon)),
    );
  }

  void _closePreviewCard() {
    setState(() {
      _selectedDonationId = null;
      _selectedDonation = null;
    });
    _rebuildMarkers();
  }

  double? _calculateDistance(double? targetLat, double? targetLon) {
    if (_currentPosition == null || targetLat == null || targetLon == null) {
      return null;
    }
    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          targetLat,
          targetLon,
        ) /
        1000;
  }

  String _formatUrgency(dynamic expiryDateRaw) {
    if (expiryDateRaw == null) return 'Fresh / Available';
    DateTime? expiry;
    if (expiryDateRaw is Timestamp) {
      expiry = expiryDateRaw.toDate();
    } else if (expiryDateRaw is DateTime) {
      expiry = expiryDateRaw;
    } else if (expiryDateRaw is String) {
      expiry = DateTime.tryParse(expiryDateRaw);
    }
    if (expiry == null) return 'Fresh / Available';

    final now = DateTime.now();
    final diff = expiry.difference(now);

    if (diff.isNegative) {
      return 'Expired';
    } else if (diff.inMinutes < 60) {
      return 'Urgent: ${diff.inMinutes}m left!';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    } else if (diff.inDays == 1) {
      return 'Expires tomorrow';
    } else {
      return 'Expires in ${diff.inDays} days';
    }
  }

  Color _formatUrgencyColor(dynamic expiryDateRaw) {
    if (expiryDateRaw == null) return const Color(0xFF2E7D32);
    DateTime? expiry;
    if (expiryDateRaw is Timestamp) {
      expiry = expiryDateRaw.toDate();
    } else if (expiryDateRaw is DateTime) {
      expiry = expiryDateRaw;
    } else if (expiryDateRaw is String) {
      expiry = DateTime.tryParse(expiryDateRaw);
    }
    if (expiry == null) return const Color(0xFF2E7D32);

    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative || diff.inHours <= 3) {
      return const Color(0xFFD32F2F);
    } else if (diff.inHours <= 12) {
      return const Color(0xFFF57C00);
    } else {
      return const Color(0xFF2E7D32);
    }
  }

  Future<void> _launchDirections(double lat, double lon) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map navigation: $e')),
        );
      }
    }
  }

  void _showQuickRequestModal(Map<String, dynamic> donation) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make a request')),
      );
      return;
    }

    if (user.uid == donation['donorId']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot request your own donation listing.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final messageController = TextEditingController(
      text: 'Hello, I would like to request this surplus food for our community. I can pick it up promptly.',
    );
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _leaf.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.handshake_rounded, color: _leaf, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Request',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        Text(
                          donation['title'] ?? 'Food Donation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _slate,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Pickup Message for Donor:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add an optional note about pickup timing or quantity needed...',
                  fillColor: _mist,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          try {
                            await _firestoreService.createRequest(
                              recipientId: user.uid,
                              donationId: donation['id'],
                              message: messageController.text.trim(),
                              recipientName: user.displayName ?? 'Recipient',
                              recipientEmail: user.email ?? '',
                            );

                            if (context.mounted) {
                              setState(() {
                                _userRequestedDonationIds.add(donation['id']);
                              });
                              Navigator.pop(context);
                              _closePreviewCard();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Colors.white),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Request sent! Donor will be notified.',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: _leaf,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            final errorMsg = e.toString().replaceAll('Exception:', '').trim();
                            final isAlreadyRequested = errorMsg.toLowerCase().contains('already requested');

                            if (isAlreadyRequested) {
                              setState(() {
                                _userRequestedDonationIds.add(donation['id']);
                              });
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        isAlreadyRequested ? Icons.info_outline_rounded : Icons.error_outline_rounded,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          isAlreadyRequested
                                              ? 'You have already requested this donation.'
                                              : errorMsg,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: isAlreadyRequested ? Colors.orange.shade800 : Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _leaf,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Send Request Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Map by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _ink),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _filterCategories.map((cat) {
                final isSelected = _selectedFilter == cat;
                final config = cat == 'All' ? null : getCategoryConfig(cat);
                return ChoiceChip(
                  label: Text('${config?.emoji ?? "🌐"} $cat'),
                  selected: isSelected,
                  selectedColor: _leaf,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : _ink,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = cat;
                    });
                    _rebuildMarkers();
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: _mist,
      appBar: AppBar(
        toolbarHeight: 74,
        titleSpacing: 18,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Donation Map',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 2),
            Text(
              'Live pins & nearby surplus food',
              style: TextStyle(fontSize: 12, color: Color(0xFFA8C9A7), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: _forest,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _heroGradient)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.my_location_rounded, size: 18),
            ),
            tooltip: 'My Location',
            onPressed: _getCurrentLocation,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedFilter == 'All' ? Colors.white.withValues(alpha: 0.12) : _sprout,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.filter_list_rounded,
                size: 18,
                color: _selectedFilter == 'All' ? Colors.white : _forest,
              ),
            ),
            tooltip: 'Filter Category',
            onPressed: _showFilterSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_leaf)),
                  SizedBox(height: 12),
                  Text('Loading donation map & live pins...'),
                ],
              ),
            )
          : Stack(
              children: [
                // 1. Full Interactive Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : _defaultLocation,
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: (_) {
                    if (_selectedDonation != null) {
                      _closePreviewCard();
                    }
                  },
                ),

                // 2. Category Quick-Filter Floating Chips
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _filterCategories.map((cat) {
                        final isSelected = _selectedFilter == cat;
                        final config = cat == 'All' ? null : getCategoryConfig(cat);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Material(
                            elevation: isSelected ? 3 : 1,
                            shadowColor: Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                            color: isSelected ? _forest : Colors.white,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                setState(() {
                                  _selectedFilter = cat;
                                });
                                _rebuildMarkers();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                child: Row(
                                  children: [
                                    Text(config?.emoji ?? '🌐', style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? Colors.white : _ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // 3. Zoom / Center Floating Action Buttons
                Positioned(
                  right: 14,
                  bottom: _selectedDonation != null ? 240 : 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'zoom_in',
                        onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                        backgroundColor: _cardBg,
                        elevation: 3,
                        child: const Icon(Icons.add, color: _leaf),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'zoom_out',
                        onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                        backgroundColor: _cardBg,
                        elevation: 3,
                        child: const Icon(Icons.remove, color: _leaf),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'center_map',
                        onPressed: _getCurrentLocation,
                        backgroundColor: _leaf,
                        elevation: 3,
                        child: const Icon(Icons.my_location_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // 4. Interactive Bottom Sheet Preview Card (Glides up on marker tap)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  left: 14,
                  right: 14,
                  bottom: _selectedDonation != null ? 16 : -320,
                  child: _selectedDonation == null
                      ? const SizedBox.shrink()
                      : _buildBottomPreviewCard(_selectedDonation!),
                ),
              ],
            ),
    );
  }

  Widget _buildBottomPreviewCard(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Food Donation';
    final category = data['category'] ?? 'Food';
    final quantity = data['quantity'] ?? '';
    final location = data['location'] ?? 'Nearby pickup point';
    final lat = (data['latitude'] as num?)?.toDouble();
    final lon = (data['longitude'] as num?)?.toDouble();
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final config = getCategoryConfig(category);
    final distanceKm = _calculateDistance(lat, lon);
    final urgencyText = _formatUrgency(data['expiryDate']);
    final urgencyColor = _formatUrgencyColor(data['expiryDate']);
    final isAlreadyRequested = _userRequestedDonationIds.contains(data['id']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category badge & Urgency Timer & "Full Details" button & Close Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(config.emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      config.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: config.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 13, color: urgencyColor),
                    const SizedBox(width: 4),
                    Text(
                      urgencyText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: urgencyColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showFullDetailsModal(data),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _leaf.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _leaf),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.north_east_rounded, size: 12, color: _leaf),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _closePreviewCard,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: _mist,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: _slate),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Main Info Row: Thumbnail + Title + Quantity + Distance (Tappable to expand)
          InkWell(
            onTap: () => _showFullDetailsModal(data),
            borderRadius: BorderRadius.circular(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Photo Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrls.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: _mist,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: _mist,
                            child: Center(
                              child: Text(config.emoji, style: const TextStyle(fontSize: 28)),
                            ),
                          ),
                        )
                      : Container(
                          color: config.color.withValues(alpha: 0.15),
                          child: Center(
                            child: Text(config.emoji, style: const TextStyle(fontSize: 32)),
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 14),

              // Title, Quantity & Distance details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quantity: $quantity',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _slate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: _leaf),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            distanceKm != null
                                ? '${distanceKm.toStringAsFixed(1)} km away • $location'
                                : location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _slate,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

          const SizedBox(height: 14),

          // Action Buttons: Directions + Quick Request
          Row(
            children: [
              if (lat != null && lon != null)
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => _launchDirections(lat, lon),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text('Directions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _forest,
                      side: const BorderSide(color: _divider, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (lat != null && lon != null) const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: isAlreadyRequested
                    ? OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: Colors.white),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'You already have an active request for this donation.',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 18, color: _leaf),
                        label: const Text('Requested ✓'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _leaf,
                          side: const BorderSide(color: _leaf, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _showQuickRequestModal(data),
                        icon: const Icon(Icons.handshake_rounded, size: 18),
                        label: const Text('Quick Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _leaf,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullDetailsModal(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Food Donation';
    final description = (data['description'] != null && data['description'].toString().trim().isNotEmpty)
        ? data['description'].toString()
        : 'No extra description provided by donor.';
    final category = data['category'] ?? 'Other';
    final condition = data['condition'] ?? 'Fresh';
    final quantity = data['quantity'] ?? '1';
    final location = data['location'] ?? 'Pickup location not specified';
    final donorName = data['donorName']?.toString() ?? 'Community Donor';
    final donorPhone = data['donorPhone']?.toString() ?? '';
    final lat = (data['latitude'] as num?)?.toDouble();
    final lon = (data['longitude'] as num?)?.toDouble();
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final config = getCategoryConfig(category);
    final distanceKm = _calculateDistance(lat, lon);
    final urgencyText = _formatUrgency(data['expiryDate']);
    final urgencyColor = _formatUrgencyColor(data['expiryDate']);
    final isAlreadyRequested = _userRequestedDonationIds.contains(data['id']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: _divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Gallery / Hero Header
                      if (imageUrls.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: CachedNetworkImage(
                            imageUrl: imageUrls.first,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 220,
                              color: _mist,
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 220,
                              color: _mist,
                              child: Center(
                                child: Text(config.emoji, style: const TextStyle(fontSize: 48)),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: config.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(config.emoji, style: const TextStyle(fontSize: 48)),
                                const SizedBox(height: 6),
                                Text(
                                  config.label,
                                  style: TextStyle(color: config.color, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 18),

                      // Badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: config.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(config.emoji, style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 5),
                                Text(
                                  config.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: config.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: urgencyColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 13, color: urgencyColor),
                                const SizedBox(width: 4),
                                Text(
                                  urgencyText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: urgencyColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (condition.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _mist,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                condition,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 14),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Quantity: $quantity',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _leaf),
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF425244)),
                      ),

                      const SizedBox(height: 18),
                      const Text(
                        'Pickup Location',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _mist,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: _leaf, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    location,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _ink,
                                    ),
                                  ),
                                  if (distanceKm != null)
                                    Text(
                                      '${distanceKm.toStringAsFixed(1)} km away from your location',
                                      style: const TextStyle(fontSize: 12, color: _slate),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),
                      const Text(
                        'Donor Contact',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _mist,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _divider),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _leaf.withValues(alpha: 0.15),
                              child: const Icon(Icons.person, color: _leaf),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    donorName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _ink,
                                    ),
                                  ),
                                  Text(
                                    donorPhone.isNotEmpty ? donorPhone : 'Phone available upon acceptance',
                                    style: const TextStyle(fontSize: 12, color: _slate),
                                  ),
                                ],
                              ),
                            ),
                            if (donorPhone.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.phone_rounded, color: _leaf),
                                onPressed: () async {
                                  final uri = Uri.parse('tel:$donorPhone');
                                  if (await canLaunchUrl(uri)) launchUrl(uri);
                                },
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),

              // Bottom Action Dock in Full Details
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (lat != null && lon != null)
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () => _launchDirections(lat, lon),
                          icon: const Icon(Icons.directions_rounded, size: 18),
                          label: const Text('Directions'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _forest,
                            side: const BorderSide(color: _divider, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    if (lat != null && lon != null) const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: isAlreadyRequested
                          ? OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You already have an active request for this donation.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check_circle_rounded, size: 18, color: _leaf),
                              label: const Text('Requested ✓'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _leaf,
                                side: const BorderSide(color: _leaf, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showQuickRequestModal(data);
                              },
                              icon: const Icon(Icons.handshake_rounded, size: 18),
                              label: const Text('Request Donation'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _leaf,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}


