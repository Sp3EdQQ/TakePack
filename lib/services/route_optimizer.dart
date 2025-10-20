import 'package:latlong2/latlong.dart';
import '../models/delivery_point.dart';
import 'routing_service.dart';

/// Service for optimizing delivery route order using nearest neighbor algorithm
class RouteOptimizer {
  final RoutingService _routingService;

  RouteOptimizer(this._routingService);

  /// Optimize route order starting from user's current position
  /// Uses greedy nearest neighbor algorithm for TSP approximation
  Future<List<DeliveryPoint>> optimizeRoute({
    required List<DeliveryPoint> points,
    required LatLng startPosition,
  }) async {
    if (points.isEmpty) return [];
    if (points.length == 1) return points;

    final optimized = <DeliveryPoint>[];
    final remaining = List<DeliveryPoint>.from(points);
    LatLng currentPos = startPosition;

    // Greedy nearest neighbor: always pick closest unvisited point
    while (remaining.isNotEmpty) {
      DeliveryPoint? nearest;
      double minDistance = double.infinity;

      // Find nearest unvisited point
      for (final point in remaining) {
        final pointLatLng = LatLng(point.lat, point.lng);

        // Try to get real route distance, fallback to straight-line
        double distance;
        try {
          final routeInfo = await _routingService.getRouteInfo([
            currentPos,
            pointLatLng,
          ]);
          distance = routeInfo.distanceMeters;
        } catch (_) {
          // Fallback to straight-line distance
          distance = const Distance().as(
            LengthUnit.Meter,
            currentPos,
            pointLatLng,
          );
        }

        if (distance < minDistance) {
          minDistance = distance;
          nearest = point;
        }
      }

      if (nearest != null) {
        optimized.add(nearest);
        remaining.remove(nearest);
        currentPos = LatLng(nearest.lat, nearest.lng);
      }
    }

    return optimized;
  }

  /// Quick optimization using only straight-line distances (faster but less accurate)
  List<DeliveryPoint> optimizeRouteQuick({
    required List<DeliveryPoint> points,
    required LatLng startPosition,
  }) {
    if (points.isEmpty) return [];
    if (points.length == 1) return points;

    final optimized = <DeliveryPoint>[];
    final remaining = List<DeliveryPoint>.from(points);
    LatLng currentPos = startPosition;

    while (remaining.isNotEmpty) {
      DeliveryPoint? nearest;
      double minDistance = double.infinity;

      for (final point in remaining) {
        final pointLatLng = LatLng(point.lat, point.lng);
        final distance = const Distance().as(
          LengthUnit.Meter,
          currentPos,
          pointLatLng,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = point;
        }
      }

      if (nearest != null) {
        optimized.add(nearest);
        remaining.remove(nearest);
        currentPos = LatLng(nearest.lat, nearest.lng);
      }
    }

    return optimized;
  }

  /// Calculate total route distance for given order
  Future<double> calculateTotalDistance(
    List<LatLng> waypoints,
  ) async {
    if (waypoints.length < 2) return 0;

    double total = 0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      try {
        final routeInfo = await _routingService.getRouteInfo([
          waypoints[i],
          waypoints[i + 1],
        ]);
        total += routeInfo.distanceMeters;
      } catch (_) {
        // Fallback to straight-line
        total += const Distance().as(
          LengthUnit.Meter,
          waypoints[i],
          waypoints[i + 1],
        );
      }
    }
    return total;
  }
}
