import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/delivery_point.dart';
import '../services/api_service.dart';
import '../services/routing_service.dart';

class MapPage extends StatefulWidget {
  final ApiService apiService;
  const MapPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late Future<List<DeliveryPoint>> _pointsFuture;
  Position? _currentPosition;
  StreamSubscription<Position>? _posSub;
  final Set<String> _notified = {};
  final double _proximityThreshold = 30.0; // meters
  final MapController _mapController = MapController();
  final RoutingService _routingService = RoutingService();

  // Route polylines (cached)
  List<LatLng>? _routeBetweenPoints;
  List<LatLng>? _routeToFirstPoint;
  bool _loadingRoutes = false;

  @override
  void initState() {
    super.initState();
    _pointsFuture = widget.apiService.fetchPoints();
    _initLocation();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => _loadingRoutes = true);
    final points = await _pointsFuture;
    if (points.isEmpty) {
      setState(() => _loadingRoutes = false);
      return;
    }

    // Fetch route between delivery points
    final deliveryWaypoints = points.map((p) => LatLng(p.lat, p.lng)).toList();
    _routeBetweenPoints = await _routingService.getRoute(deliveryWaypoints);

    // Fetch route from user location to first point (if available)
    if (_currentPosition != null) {
      final userToFirst = [
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        deliveryWaypoints.first,
      ];
      _routeToFirstPoint = await _routingService.getRoute(userToFirst);
    }

    if (mounted) setState(() => _loadingRoutes = false);
  }

  Future<void> _updateRouteToFirstPoint(Position p) async {
    final points = await _pointsFuture;
    if (points.isEmpty) return;

    final userToFirst = [
      LatLng(p.latitude, p.longitude),
      LatLng(points.first.lat, points.first.lng),
    ];
    final route = await _routingService.getRoute(userToFirst);
    if (mounted) {
      setState(() => _routeToFirstPoint = route);
    }
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return; // permission not granted
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      if (!mounted) return;
      setState(() => _currentPosition = pos);

      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best, distanceFilter: 5),
      ).listen((p) {
        if (!mounted) return;
        setState(() => _currentPosition = p);
        _checkProximity(p);
        _updateRouteToFirstPoint(p);
      });
    } catch (_) {
      // ignore location errors
    }
  }

  Future<void> _checkProximity(Position p) async {
    final points = await _pointsFuture;
    for (final point in points) {
      if (_notified.contains(point.id)) continue;
      final d = Geolocator.distanceBetween(
          p.latitude, p.longitude, point.lat, point.lng);
      if (d <= _proximityThreshold) {
        _notified.add(point.id);
        if (!mounted) return;
        _showPickupDialog(point, d);
      }
    }
  }

  void _showPickupDialog(DeliveryPoint point, double distanceMeters) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(point.name),
        content:
            Text('Jesteś ~${distanceMeters.toStringAsFixed(0)} m od punktu.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TakePack Map')),
      body: FutureBuilder<List<DeliveryPoint>>(
        future: _pointsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final points = snapshot.data ?? <DeliveryPoint>[];
          if (points.isEmpty) return const Center(child: Text('No points'));

          final markers = points
              .map((p) => Marker(
                    width: 40,
                    height: 40,
                    point: LatLng(p.lat, p.lng),
                    child: const Icon(Icons.location_on,
                        color: Colors.red, size: 36),
                  ))
              .toList();

          // add user marker
          if (_currentPosition != null) {
            markers.add(Marker(
              width: 40,
              height: 40,
              point: LatLng(
                  _currentPosition!.latitude, _currentPosition!.longitude),
              child: const Icon(Icons.person_pin_circle,
                  color: Colors.blue, size: 36),
            ));
          }

          final polylinePoints =
              points.map((p) => LatLng(p.lat, p.lng)).toList();

          final center = _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : polylinePoints.first;

          // Create polylines list using routed paths (or fallback to straight lines)
          final polylines = <Polyline>[];

          // Blue line connecting delivery points (use routing if available)
          if (_routeBetweenPoints != null && _routeBetweenPoints!.isNotEmpty) {
            polylines.add(Polyline(
                points: _routeBetweenPoints!,
                color: Colors.blue,
                strokeWidth: 4.0));
          } else if (!_loadingRoutes) {
            // Fallback to straight line if routing not loaded yet
            polylines.add(Polyline(
                points: polylinePoints, color: Colors.blue, strokeWidth: 4.0));
          }

          // Add green line from user location to first delivery point (use routing)
          if (_routeToFirstPoint != null && _routeToFirstPoint!.isNotEmpty) {
            polylines.add(Polyline(
              points: _routeToFirstPoint!,
              color: Colors.green,
              strokeWidth: 3.0,
            ));
          } else if (_currentPosition != null &&
              polylinePoints.isNotEmpty &&
              !_loadingRoutes) {
            // Fallback to straight line
            polylines.add(Polyline(
              points: [
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                polylinePoints.first,
              ],
              color: Colors.green,
              strokeWidth: 3.0,
            ));
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(initialCenter: center, initialZoom: 15),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  PolylineLayer(polylines: polylines),
                  MarkerLayer(markers: markers),
                ],
              ),
              // Show loading indicator while fetching routes
              if (_loadingRoutes)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Loading route...',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }
}
