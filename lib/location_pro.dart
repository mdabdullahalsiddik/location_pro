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
class LatLng {
  /// Latitude in decimal degrees.
  final double latitude;

  /// Longitude in decimal degrees.
  final double longitude;

  /// Creates a new [LatLng] object with given [latitude] and [longitude].
  LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

/// Service for fetching the current location and resolving human-readable
/// addresses from latitude/longitude coordinates.
///
/// Supports live GPS tracking on mobile and periodic location updates
/// on web/desktop. Can also fetch addresses in multiple languages.
class LocationPro {
  /// Current location as [LatLng]. Null if not fetched yet.
  final ValueNotifier<LatLng?> currentLocation = ValueNotifier<LatLng?>(null);

  /// Human-readable address for the current location.
  final ValueNotifier<String> placeName = ValueNotifier<String>("");

  StreamSubscription<Position>? _positionStream;
  Timer? _webTimer;

  /// Address language code according to OpenStreetMap Nominatim (default: 'en')
  String language;

  /// Creates a [LocationPro] service instance.
  ///
  /// Set [language] for default address language.
  /// If [autoStart] is true, tracking will start automatically.
  LocationPro({this.language = 'en', bool autoStart = false}) {
    if (autoStart) startTracking();
  }

  /// Starts tracking location.
  ///
  /// On mobile: uses live GPS.
  /// On web/desktop: uses periodic updates.
  ///
  /// Optionally provide [latLng] to track a fixed location without live GPS.
  void startTracking([LatLng? latLng]) {
    _stopInternalTimers();

    if (latLng != null) {
      currentLocation.value = latLng;
      _getPlaceName(latLng.latitude, latLng.longitude);
      return;
    }

    if (kIsWeb || !_isMobile()) {
      _webTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        await fetchCurrentLocation();
      });
    } else {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position position) async {
        currentLocation.value = LatLng(position.latitude, position.longitude);
        await _getPlaceName(position.latitude, position.longitude);
      });
    }
  }

  /// Stops tracking location.
  void stopTracking() {
    _stopInternalTimers();
  }

  void _stopInternalTimers() {
    _positionStream?.cancel();
    _positionStream = null;
    _webTimer?.cancel();
    _webTimer = null;
  }

  bool _isMobile() =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Fetches the current location once and updates [currentLocation] and [placeName].
  Future<void> fetchCurrentLocation() async {
    try {
      final Position position = await _determinePosition();
      currentLocation.value = LatLng(position.latitude, position.longitude);
      await _getPlaceName(position.latitude, position.longitude);

      log('✅ Current location: ${currentLocation.value}');
      log('📍 Address: ${placeName.value}');
    } catch (e, st) {
      log('❌ fetchCurrentLocation error: $e');
      log(st.toString());
      placeName.value = 'Address not available';
    }
  }

  /// Fetches the address for given coordinates [lat], [lng].
  ///
  /// Uses [language] for multi-language support.
  Future<void> _getPlaceName(double lat, double lng) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&accept-language=$language';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'location_pro/1.0 (your_email@example.com)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final display = data['display_name'] as String?;
        placeName.value = display ?? 'Address not available';
      } else {
        placeName.value = 'Address not available';
      }
    } catch (e) {
      log('❌ Nominatim error: $e');
      placeName.value = 'Address not available';
    }
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied.');
    }

    // ✅ Fixed deprecated API: using LocationSettings instead of desiredAccuracy
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Disposes timers and ValueNotifiers.
  void dispose() {
    _stopInternalTimers();
    currentLocation.dispose();
    placeName.dispose();
  }
}
