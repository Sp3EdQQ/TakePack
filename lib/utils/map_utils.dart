import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/delivery_point.dart';

/// Utility functions for map operations
class MapUtils {
  /// Create delivery point markers
  static List<Marker> createDeliveryMarkers(List<DeliveryPoint> points) {
    return points
        .map((p) => Marker(
              width: 40,
              height: 40,
              point: LatLng(p.lat, p.lng),
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 36,
              ),
            ))
        .toList();
  }

  /// Create user location marker
  static Marker? createUserMarker(Position? position) {
    if (position == null) return null;

    return Marker(
      width: 40,
      height: 40,
      point: LatLng(position.latitude, position.longitude),
      child: const Icon(
        Icons.person_pin_circle,
        color: Colors.blue,
        size: 36,
      ),
    );
  }

  /// Create polylines for routes
  static List<Polyline> createPolylines({
    required List<LatLng>? routeBetweenPoints,
    required List<LatLng>? routeToFirstPoint,
    required List<LatLng> fallbackPoints,
    required Position? currentPosition,
    required bool isLoading,
  }) {
    final polylines = <Polyline>[];

    // Blue line connecting delivery points
    if (routeBetweenPoints != null && routeBetweenPoints.isNotEmpty) {
      polylines.add(Polyline(
        points: routeBetweenPoints,
        color: Colors.blue,
        strokeWidth: 4.0,
      ));
    } else if (!isLoading && fallbackPoints.isNotEmpty) {
      // Fallback to straight line
      polylines.add(Polyline(
        points: fallbackPoints,
        color: Colors.blue,
        strokeWidth: 4.0,
      ));
    }

    // Green line from user to first point
    if (routeToFirstPoint != null && routeToFirstPoint.isNotEmpty) {
      polylines.add(Polyline(
        points: routeToFirstPoint,
        color: Colors.green,
        strokeWidth: 3.0,
      ));
    } else if (currentPosition != null &&
        fallbackPoints.isNotEmpty &&
        !isLoading) {
      // Fallback to straight line
      polylines.add(Polyline(
        points: [
          LatLng(currentPosition.latitude, currentPosition.longitude),
          fallbackPoints.first,
        ],
        color: Colors.green,
        strokeWidth: 3.0,
      ));
    }

    return polylines;
  }

  /// Get map center point
  static LatLng getMapCenter({
    required Position? currentPosition,
    required List<LatLng> fallbackPoints,
  }) {
    if (currentPosition != null) {
      return LatLng(currentPosition.latitude, currentPosition.longitude);
    }
    return fallbackPoints.isNotEmpty
        ? fallbackPoints.first
        : LatLng(52.2297, 21.0122); // Default Warsaw
  }
}
