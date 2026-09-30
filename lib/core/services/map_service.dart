import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';

class MapService {
  // Request location permission with better handling
  Future<bool> requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled');
        return false;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('📍 Current permission: $permission');

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        debugPrint('📍 After request: $permission');

        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission denied forever - opening settings');
        // Open app settings
        await Geolocator.openAppSettings();
        return false;
      }

      debugPrint('✅ Location permission granted');
      return true;
    } catch (e) {
      debugPrint('❌ Error requesting permission: $e');
      return false;
    }
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      debugPrint('🔵 Getting current location...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled.');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('📍 Permission status: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permissions are permanently denied');
        await Geolocator.openAppSettings();
        return null;
      }

      // Get current position
      debugPrint('🔵 Fetching GPS coordinates...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('✅ Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      return null;
    }
  }

  // Get address from coordinates
  Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      debugPrint('🔵 Getting address for: $lat, $lon');
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        List<String> parts = [];
        if (place.name != null && place.name!.isNotEmpty && place.name != place.street) parts.add(place.name!);
        if (place.street != null && place.street!.isNotEmpty) parts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty) parts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) parts.add(place.administrativeArea!);
        if (place.postalCode != null && place.postalCode!.isNotEmpty) parts.add(place.postalCode!);
        if (place.country != null && place.country!.isNotEmpty) parts.add(place.country!);

        String address = parts.join(', ');
        debugPrint('✅ Address: $address');
        return address.isNotEmpty ? address : null;
      }
    } catch (e) {
      debugPrint('❌ Native geocoding failed, trying OSM fallback: $e');
      return await _getOsmAddress(lat, lon);
    }
    return null;
  }

  // OpenStreetMap fallback for emulators or devices without Play Services
  Future<String?> _getOsmAddress(double lat, double lon) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1');
      final client = HttpClient();
      final request = await client.getUrl(url);
      request.headers.set('User-Agent', 'HarvestHubApp/1.0 (Contact: support@harvesthub.com)');
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        final data = json.decode(stringData);
        if (data != null && data['display_name'] != null) {
          debugPrint('✅ OSM Address: ${data['display_name']}');
          return data['display_name'];
        }
      }
    } catch (e) {
      debugPrint('❌ OSM fallback failed: $e');
    }
    return null;
  }

  // Get coordinates from address
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations[0];
      }
    } catch (e) {
      debugPrint('❌ Error getting coordinates: $e');
    }
    return null;
  }

  // Calculate distance between two points (in km)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}