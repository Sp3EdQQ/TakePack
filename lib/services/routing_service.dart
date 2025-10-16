import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  // OSRM public API (free, no key required)
  static const String _baseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  /// Fetch route between multiple points (returns list of LatLng coordinates along the route)
  Future<List<LatLng>> getRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return waypoints;

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
          // OSRM returns [lng, lat] pairs
          return geometry
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
              .toList();
        }
      }
    } catch (_) {
      // on error, return straight line
    }
    return waypoints; // fallback to straight line
  }
}
