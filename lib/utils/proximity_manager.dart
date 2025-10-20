import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/delivery_point.dart';

/// Utility class for proximity detection and notifications
class ProximityManager {
  final Set<String> _notifiedPoints = {};
  final double _proximityThreshold;

  ProximityManager({double proximityThreshold = 30.0})
      : _proximityThreshold = proximityThreshold;

  /// Check if user is near any delivery point and show dialog if needed
  Future<void> checkProximity({
    required BuildContext context,
    required Position position,
    required List<DeliveryPoint> points,
  }) async {
    for (final point in points) {
      if (_notifiedPoints.contains(point.id)) continue;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        point.lat,
        point.lng,
      );

      if (distance <= _proximityThreshold) {
        _notifiedPoints.add(point.id);
        _showPickupDialog(context, point, distance);
      }
    }
  }

  /// Show pickup confirmation dialog
  void _showPickupDialog(
    BuildContext context,
    DeliveryPoint point,
    double distanceMeters,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(point.name),
        content: Text(
          'Jesteś ~${distanceMeters.toStringAsFixed(0)} m od punktu.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: call API to mark as picked up
            },
            child: const Text('Odbierz'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Później'),
          ),
        ],
      ),
    );
  }

  /// Reset notification state (useful for testing)
  void reset() {
    _notifiedPoints.clear();
  }
}
