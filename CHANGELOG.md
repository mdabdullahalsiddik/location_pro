# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2] - 2025-09-08
### Added
- Documented Update

## [1.0.1] - 2025-09-07
### Added
- Added dartdoc comments to all public API elements for better documentation.
- Improved multi-language support for reverse geocoding.
- Added optional `autoStart` parameter in `LocationPro` constructor to start tracking automatically.

### Fixed
- Fixed minor bugs in `fetchCurrentLocation()` error handling.
- Improved stability for web/desktop periodic updates.

## [1.0.0] - 2025-09-07
### Added
- Initial release of `location_pro` Flutter package.
- Main class `LocationPro` for fetching current location and addresses.
- Supports live GPS tracking on mobile and periodic polling on web/desktop.
- Reverse geocoding with OpenStreetMap Nominatim.
- Multi-language support for addresses via `language` parameter.
- `ValueNotifier<LatLng?> currentLocation` and `ValueNotifier<String> placeName` for UI updates.
- Dispose method to stop timers and streams.
- `LatLng` model included.
- Example app demonstrating usage.
- MIT License included.
