
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationPro {
  final ValueNotifier<LatLng?> currentLocation = ValueNotifier<LatLng?>(null);
  final ValueNotifier<String> placeName = ValueNotifier<String>("");

  StreamSubscription<Position>? _positionStream;
  Timer? _webTimer;

  /// Address language code according to OpenStreetMap Nominatim (default: 'en')
  String language;

  LocationPro({this.language = 'en', bool autoStart = false}) {
    if (autoStart) startTracking();
  }

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

  Future<void> _getPlaceName(double lat, double lng) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&accept-language=$language';

      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'location_pro/1.0 (your_email@example.com)'
      });

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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception('Location permissions denied.');
    }

    if (permission == LocationPermission.deniedForever) throw Exception('Location permissions permanently denied.');

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void dispose() {
    _stopInternalTimers();
    currentLocation.dispose();
    placeName.dispose();
  }
}

class LatLng {
  final double latitude;
  final double longitude;
  LatLng(this.latitude, this.longitude);
  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

