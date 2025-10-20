import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/delivery_point.dart';
import '../services/api_service.dart';
import '../services/routing_service.dart';
import '../services/location_service.dart';
import '../widgets/route_info_bar.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/center_location_button.dart';
import '../utils/proximity_manager.dart';
import '../utils/map_utils.dart';

class MapPage extends StatefulWidget {
  final ApiService apiService;
  const MapPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Services
  late Future<List<DeliveryPoint>> _pointsFuture;
  final MapController _mapController = MapController();
  final RoutingService _routingService = RoutingService();
  final LocationService _locationService = LocationService();
  final ProximityManager _proximityManager = ProximityManager();

  // State
  List<LatLng>? _routeBetweenPoints;
  List<LatLng>? _routeToFirstPoint;
  RouteInfo? _routeInfoToFirst;
  bool _loadingRoutes = false;

  @override
  void initState() {
    super.initState();
    _pointsFuture = widget.apiService.fetchPoints();
    _initLocation();
    _loadRoutes();
  }

  /// Initialize location tracking
  Future<void> _initLocation() async {
    await _locationService.initialize(
      onPositionUpdate: _onPositionUpdate,
    );
  }

  /// Handle position updates from location service
  void _onPositionUpdate(Position position) {
    if (!mounted) return;
    setState(() {});
    _checkProximity(position);
    _updateRouteToFirstPoint(position);
  }

  /// Load routes between delivery points and to first point
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
    final currentPos = _locationService.currentPosition;
    if (currentPos != null) {
      final userToFirst = [
        LatLng(currentPos.latitude, currentPos.longitude),
        deliveryWaypoints.first,
      ];
      _routeInfoToFirst = await _routingService.getRouteInfo(userToFirst);
      _routeToFirstPoint = _routeInfoToFirst?.coordinates;
    }

    if (mounted) setState(() => _loadingRoutes = false);
  }

  /// Update route to first delivery point when user moves
  Future<void> _updateRouteToFirstPoint(Position position) async {
    final points = await _pointsFuture;
    if (points.isEmpty) return;

    final userToFirst = [
      LatLng(position.latitude, position.longitude),
      LatLng(points.first.lat, points.first.lng),
    ];
    final routeInfo = await _routingService.getRouteInfo(userToFirst);
    if (mounted) {
      setState(() {
        _routeInfoToFirst = routeInfo;
        _routeToFirstPoint = routeInfo.coordinates;
      });
    }
  }

  /// Check if user is near any delivery point
  Future<void> _checkProximity(Position position) async {
    final points = await _pointsFuture;
    if (!mounted) return;
    await _proximityManager.checkProximity(
      context: context,
      position: position,
      points: points,
    );
  }

  /// Center map on user's current location
  void _centerOnUserLocation() {
    final position = _locationService.currentPosition;
    if (position != null) {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        16.0,
      );
    }
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
          if (points.isEmpty) {
            return const Center(child: Text('No points'));
          }

          final currentPosition = _locationService.currentPosition;
          final polylinePoints =
              points.map((p) => LatLng(p.lat, p.lng)).toList();

          // Create markers using MapUtils
          final markers = MapUtils.createDeliveryMarkers(points);
          final userMarker = MapUtils.createUserMarker(currentPosition);
          if (userMarker != null) {
            markers.add(userMarker);
          }

          // Create polylines using MapUtils
          final polylines = MapUtils.createPolylines(
            routeBetweenPoints: _routeBetweenPoints,
            routeToFirstPoint: _routeToFirstPoint,
            fallbackPoints: polylinePoints,
            currentPosition: currentPosition,
            isLoading: _loadingRoutes,
          );

          // Get map center using MapUtils
          final center = MapUtils.getMapCenter(
            currentPosition: currentPosition,
            fallbackPoints: polylinePoints,
          );

          return Stack(
            children: [
              // Map
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

              // Info bar at the top
              if (_routeInfoToFirst != null && points.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: RouteInfoBar(
                    firstPoint: points.first,
                    routeInfo: _routeInfoToFirst!,
                  ),
                ),

              // Loading indicator
              if (_loadingRoutes)
                const Positioned(
                  bottom: 90,
                  right: 16,
                  child: LoadingIndicator(),
                ),

              // Center location button
              if (currentPosition != null)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: CenterLocationButton(
                    onTap: _centerOnUserLocation,
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
    _locationService.dispose();
    super.dispose();
  }
}
