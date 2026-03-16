import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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
        String address = '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
        debugPrint('✅ Address: $address');
        return address;
      }
    } catch (e) {
      debugPrint('❌ Error getting address: $e');
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