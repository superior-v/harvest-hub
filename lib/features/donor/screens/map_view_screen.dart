import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:harvest/core/constants/app_constants.dart';
import 'package:harvest/core/services/map_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({Key? key}) : super(key: key);

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  // Theme tokens aligned with donor dashboard
  static const Color _forest = Color(0xFF1A3A1F);
  static const Color _leaf = Color(0xFF3D7A45);
  static const Color _sprout = Color(0xFF6BBF6A);
  static const Color _mist = Color(0xFFF3F7F0);
  static const Color _clay = Color(0xFFD4956A);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _divider = Color(0xFFDEEADE);
  static const Color _ink = Color(0xFF0F1F12);

  static const LinearGradient _heroGradient = LinearGradient(
    colors: [
      Color(0xFF1A3A1F),
      Color(0xFF2D5E33)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  GoogleMapController? _mapController;
  final MapService _mapService = MapService();
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  bool _isLoading = true;

  // Default location (India center)
  static const LatLng _defaultLocation = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadDonationMarkers();
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    final position = await _mapService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _currentPosition = position;
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ),
      );
    }
  }

  Future<void> _loadDonationMarkers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('donations').where('status', isEqualTo: 'available').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lat = data['latitude'] as double?;
        final lon = data['longitude'] as double?;

        if (lat != null && lon != null) {
          _markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(lat, lon),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              infoWindow: InfoWindow(
                title: data['title'] ?? 'Donation',
                snippet: '${data['category']} - ${data['quantity']}',
                onTap: () => _showDonationDetails(doc.id, data),
              ),
            ),
          );
        }
      }
      setState(() {});
    } catch (e) {
      debugPrint('Error loading markers: $e');
    }
  }

  void _showDonationDetails(String donationId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.62,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
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
                const SizedBox(height: 20),
                Text(
                  data['title'] ?? 'Donation',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.category_rounded, 'Category', data['category']),
                _buildDetailRow(Icons.inventory_2_rounded, 'Quantity', data['quantity']),
                _buildDetailRow(Icons.location_on_rounded, 'Location', data['location']),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _getDirections(data),
                        icon: const Icon(Icons.directions_rounded),
                        label: const Text('Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.roleRecipient,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _leaf,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _leaf),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, color: _ink),
          ),
          Expanded(
            child: Text(value ?? 'N/A', style: const TextStyle(color: Color(0xFF465246))),
          ),
        ],
      ),
    );
  }

  void _getDirections(Map<String, dynamic> data) {
    // Implement navigation to maps app
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening maps...'), backgroundColor: _leaf),
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
              'Nearby available items',
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
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.my_location_rounded, size: 18),
            ),
            onPressed: _getCurrentLocation,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.filter_list_rounded, size: 18),
            ),
            onPressed: () {
              // Show filter options
            },
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
                  Text('Loading donation map...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : _defaultLocation,
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            onPressed: () {
              _mapController?.animateCamera(CameraUpdate.zoomIn());
            },
            backgroundColor: _cardBg,
            child: const Icon(Icons.add, color: _leaf),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            onPressed: () {
              _mapController?.animateCamera(CameraUpdate.zoomOut());
            },
            backgroundColor: _cardBg,
            child: const Icon(Icons.remove, color: _leaf),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'center_map',
            onPressed: _getCurrentLocation,
            backgroundColor: _leaf,
            child: const Icon(Icons.my_location_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
