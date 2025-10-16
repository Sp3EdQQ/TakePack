import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteInfo {
  final List<LatLng> coordinates;
  final double distanceMeters;
  final double durationSeconds;

  RouteInfo({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  String get distanceFormatted {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get durationFormatted {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}min';
  }
}

class RoutingService {
  // OSRM public API (free, no key required)
  static const String _baseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  /// Fetch route between multiple points (returns list of LatLng coordinates along the route)
  Future<List<LatLng>> getRoute(List<LatLng> waypoints) async {
    final routeInfo = await getRouteInfo(waypoints);
    return routeInfo.coordinates;
  }

  /// Fetch route with distance and duration info
  Future<RouteInfo> getRouteInfo(List<LatLng> waypoints) async {
    if (waypoints.length < 2) {
      return RouteInfo(
        coordinates: waypoints,
        distanceMeters: 0,
        durationSeconds: 0,
      );
    }

    // Build coordinates string: lng,lat;lng,lat;...
    final coords =
        waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
    final url = '$_baseUrl/$coords?overview=full&geometries=geojson';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;
          final distance = (route['distance'] as num).toDouble();
          final duration = (route['duration'] as num).toDouble();

          // OSRM returns [lng, lat] pairs
          final coordinates = geometry
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
              .toList();

          return RouteInfo(
            coordinates: coordinates,
            distanceMeters: distance,
            durationSeconds: duration,
          );
        }
      }
    } catch (_) {
      // on error, return straight line with estimated distance
    }

    // Calculate straight line distance as fallback
    double totalDistance = 0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      final p1 = waypoints[i];
      final p2 = waypoints[i + 1];
      final distance = const Distance().as(LengthUnit.Meter, p1, p2);
      totalDistance += distance;
    }

    return RouteInfo(
      coordinates: waypoints,
      distanceMeters: totalDistance,
      durationSeconds: totalDistance / 10, // ~36 km/h estimate
    );
  }
}
