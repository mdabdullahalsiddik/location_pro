
# Location Pro 📍

A Flutter service for real-time location tracking with real-time address tracking.

It also supports direct LatLng input, allowing you to fetch addresses without live GPS, and provides multi-language address support for English, Bangla, Japanese, Chinese, and more.

---

## ✨ Features

* 📡 Real-time GPS tracking on **mobile**
* 🌍 Periodic location updates on **web/desktop**
* 🗺️ Reverse geocoding with **Nominatim API**
* 🔔 Exposes current **LatLng** & **address** as `ValueNotifier`
* 📍 Supports **direct LatLng input**: `startTracking(LatLng)`
* 🌐 Multi-language address support (English, Bangla, Japanese, Chinese, etc.)
* 📱 Cross-platform (Android, iOS, Web, Desktop)
* 🚦 Automatic **permission handling**

---

## 📦 Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  location_pro: ^1.0.0
```

Then run:

```bash
flutter pub get
```

Import the service:

```dart
import 'package:location_pro/location_pro.dart';
```

---

## 🛠️ Usage

### Initialize & Start Tracking

```dart
final locationService = LocationPro();

// Start live GPS tracking
locationService.startTracking();

// Optional: Track a specific LatLng without live GPS
// locationService.startTracking(LatLng(23.8103, 90.4125));

// Listen to live location updates
locationService.currentLocation.addListener(() {
  print("📍 Current: ${locationService.currentLocation.value}");
});

// Listen to place name updates
locationService.placeName.addListener(() {
  print("🏠 Address: ${locationService.placeName.value}");
});
```

---

### Fetch Address in Specific Language

```dart
// Example: Bangla
await locationService.getPlaceName(23.8103, 90.4125, langCode: 'bn');

// Example: Japanese
await locationService.getPlaceName(35.6895, 139.6917, langCode: 'ja');

// Example: Chinese
await locationService.getPlaceName(31.2304, 121.4737, langCode: 'zh-CN');
```

> `langCode` follows the [IETF language tag](https://en.wikipedia.org/wiki/IETF_language_tag) format.

---

### Stop Tracking

```dart
locationService.stopTracking();
```

---

### Manually Fetch Current Location

```dart
await locationService.fetchCurrentLocation();
print("📍 Location: ${locationService.currentLocation.value}");
print("🏠 Address: ${locationService.placeName.value}");
```

---

## 📌 API Reference

| Method / Property                    | Type                     | Description                                                                                           |
| ------------------------------------ | ------------------------ | ----------------------------------------------------------------------------------------------------- |
| `startTracking([LatLng?])`           | `void`                   | Starts live GPS tracking (mobile) or periodic updates (web/desktop). Can optionally provide a LatLng. |
| `stopTracking()`                     | `void`                   | Stops tracking & cancels subscriptions.                                                               |
| `fetchCurrentLocation()`             | `Future<void>`           | Fetches the current location & address once.                                                          |
| `getPlaceName(lat, lng, {langCode})` | `Future<void>`           | Fetches address for given coordinates in specified language.                                          |
| `currentLocation`                    | `ValueNotifier<LatLng?>` | Exposes the current latitude/longitude.                                                               |
| `placeName`                          | `ValueNotifier<String>`  | Exposes the resolved human-readable address.                                                          |
| `_isMobile()`                        | `bool`                   | Returns `true` if running on Android/iOS.                                                             |

---

## 🔑 Permissions Setup

### Android

Add the following permissions to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
```

### iOS

Add this to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to provide tracking features.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs your location to provide tracking features.</string>
```

---

## 📷 Example Output

```
✅ Current location: LatLng(23.8103, 90.4125)
📍 Address (English): Dhaka, Bangladesh
📍 Address (Bangla): ঢাকা, বাংলাদেশ
📍 Address (Japanese): ダッカ、バングラデシュ
📍 Address (Chinese): 达卡, 孟加拉国
```

---

## 🧩 Flutter Example Page

```dart
import 'package:flutter/material.dart';
import 'package:location_pro/location_pro.dart';

class LocationPage extends StatefulWidget {
  final LatLng? latLng;
  const LocationPage({super.key, this.latLng});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final LocationPro locationService = LocationPro();

  @override
  void initState() {
    super.initState();
    locationService.startTracking(widget.latLng);
  }

  @override
  void dispose() {
    locationService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location Pro Example")),
      body: Center(
        child: ValueListenableBuilder<String>(
          valueListenable: locationService.placeName,
          builder: (context, address, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder<LatLng?>(
                  valueListenable: locationService.currentLocation,
                  builder: (context, position, _) {
                    return Text(
                      position != null
                          ? "Lat: ${position.latitude}, Lng: ${position.longitude}"
                          : "Fetching location...",
                      style: const TextStyle(fontSize: 16),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  address.isNotEmpty ? address : "Fetching address...",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

---

## 👨‍💻 Developed By

<p align="center">
  <img src="https://raw.githubusercontent.com/mdabdullahalsiddik/RowScroller/main/assets/mdabdullahalsiddik.jpg" width="120" height="120" style="border-radius:50%" />
</p>
<h3 align="center">Md. Abdullah Al Siddik</h3>
<p align="center">
  <a href="https://github.com/mdabdullahalsiddik">
    <img src="https://img.shields.io/badge/GitHub-mdabdullahalsiddik-black?logo=github" />
  </a>
  <a href="mailto:mdabdullahalsiddik.dev@gmail.com">
    <img src="https://img.shields.io/badge/Email-mdabdullahalsiddik.dev%40gmail.com-red?logo=gmail" />
  </a>
</p>

---

## 💡 Contributing

Contributions are welcome!

1. Fork the repo
2. Create your feature branch
3. Commit your changes
4. Open a Pull Request

---

## ❤️ Support

If you like this package, give it a ⭐ on [GitHub](https://github.com/mdabdullahalsiddik) and share it!

---

I can also create a **shorter “One-page Quick Start” version** of this README for GitHub so it’s more readable and beginner-friendly.

Do you want me to do that?
