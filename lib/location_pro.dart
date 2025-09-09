import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Location Pro library for Flutter.
/// 
/// Provides **real-time location tracking** and **reverse geocoding** using
/// OpenStreetMap Nominatim API.
/// Supports Android, iOS, Web, and Desktop.

/// Simple LatLng class to store latitude and longitude
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

class LocationPro {
  // Stores current location as LatLng, updates UI when value changes
  final ValueNotifier<LatLng?> currentLocation = ValueNotifier<LatLng?>(null);

  // Stores the name/address of the current location
  final ValueNotifier<String> placeName = ValueNotifier<String>("");

  // Stores error messages like permission denied, service off, etc.
  final ValueNotifier<String> errorMessage = ValueNotifier<String>("");

  // Mobile location stream subscription
  StreamSubscription<Position>? _positionStream;

  // Web timer for periodic location fetch
  Timer? _webTimer;

  // Language code for reverse geocoding (default 'en')
  String language;

  // Constructor: optionally auto-start tracking
  LocationPro({this.language = 'en', bool autoStart = false}) {
    if (autoStart) startTracking();
  }

  /// ✅ Start tracking location
  /// [latLng] → if provided, use instantly (fast mode)
  Future<void> startTracking([LatLng? latLng]) async {
    _stopInternalTimers(); // Stop previous tracking if any
    errorMessage.value = "";

    // Fast mode: use provided LatLng immediately
    if (latLng != null) {
      currentLocation.value = latLng;
      _getPlaceName(latLng.latitude, latLng.longitude);
      return;
    }

    // Check and request permissions
    if (!await _checkAndRequestPermission()) {
      errorMessage.value = "Location permission required!";
      return;
    }

    // Web/Desktop: fetch instantly, then periodically
    if (kIsWeb || !_isMobile()) {
      await fetchCurrentLocation();
      _webTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
        fetchCurrentLocation();
      });
    } else {
      // Mobile: use position stream for real-time updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0, // update on every small change
        ),
      ).listen((Position position) {
        currentLocation.value = LatLng(position.latitude, position.longitude);
        _getPlaceName(position.latitude, position.longitude);
      });

      // Fetch first position instantly
      fetchCurrentLocation();
    }
  }

  /// ✅ Stop tracking location (mobile stream & web timer)
  void stopTracking() => _stopInternalTimers();

  /// Internal method to cancel stream and timers
  void _stopInternalTimers() {
    _positionStream?.cancel();
    _positionStream = null;
    _webTimer?.cancel();
    _webTimer = null;
  }

  /// Check if running on mobile (Android/iOS)
  bool _isMobile() =>
      defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;

  /// ✅ Fetch current location once
  Future<void> fetchCurrentLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best, // highest accuracy
        ),
      );
      // Update current location
      currentLocation.value = LatLng(position.latitude, position.longitude);
      // Fetch the address of current coordinates
      _getPlaceName(position.latitude, position.longitude);
    } catch (e, st) {
      log('❌ fetchCurrentLocation error: $e');
      log(st.toString());
      errorMessage.value = e.toString(); // Update error
    }
  }

  /// ✅ Reverse geocoding using OpenStreetMap Nominatim
  /// Converts coordinates into human-readable address
  Future<void> _getPlaceName(double lat, double lng) async {
    try {
      // Skip if already fetched recently
      if (placeName.value.isNotEmpty &&
          currentLocation.value?.latitude == lat &&
          currentLocation.value?.longitude == lng) {
        return;
      }

      final url =
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&accept-language=$language';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'location_pro/1.0 (fast_mode)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        placeName.value = data['display_name'] ?? ''; // Update address
      } else {
        placeName.value = ''; // Clear if error
      }
    } catch (_) {
      placeName.value = ''; // Clear on exception
    }
  }

  /// ✅ Permission check and request
  Future<bool> _checkAndRequestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      errorMessage.value = 'Location service is OFF. Enable it!';
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        errorMessage.value = 'Location permission denied!';
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      errorMessage.value =
      'Permission permanently denied. Please enable in settings.';
      return false;
    }

    return true;
  }

  /// Dispose method to clean up streams and notifiers
  void dispose() {
    _stopInternalTimers();
    currentLocation.dispose();
    placeName.dispose();
    errorMessage.dispose();
  }
}
