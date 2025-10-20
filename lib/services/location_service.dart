import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Service for managing user location tracking
class LocationService {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  Position? get currentPosition => _currentPosition;

  /// Initialize location tracking with permission handling
  Future<void> initialize({
    required Function(Position) onPositionUpdate,
  }) async {
    try {
      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return; // Permission not granted
      }

      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // Notify initial position
      if (_currentPosition != null) {
        onPositionUpdate(_currentPosition!);
      }

      // Start listening to position updates
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5, // Update every 5 meters
        ),
      ).listen((position) {
        _currentPosition = position;
        onPositionUpdate(position);
      });
    } catch (e) {
      // Ignore location errors silently
    }
  }

  /// Stop location tracking and clean up
  void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
