import 'package:flutter/material.dart';
import 'package:location_pro/location_pro.dart'; // Import your package

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LocationPro _location = LocationPro(language: 'en'); // Change to 'bn' for Bangla

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('LocationPro Example')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () => _location.startTracking(),
                child: const Text('Start Tracking'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _location.stopTracking(),
                child: const Text('Stop Tracking'),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<LatLng?>(
                valueListenable: _location.currentLocation,
                builder: (context, loc, _) {
                  return Text(loc != null
                      ? 'Lat: ${loc.latitude}, Lng: ${loc.longitude}'
                      : 'Location: unknown');
                },
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<String>(
                valueListenable: _location.placeName,
                builder: (context, name, _) {
                  return Text('Address: ${name.isEmpty ? 'Fetching...' : name}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
