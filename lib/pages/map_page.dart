import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/delivery_point.dart';
import '../services/api_service.dart';

class MapPage extends StatefulWidget {
  final ApiService apiService;
  const MapPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late Future<List<DeliveryPoint>> _pointsFuture;

  @override
  void initState() {
    super.initState();
    _pointsFuture = widget.apiService.fetchPoints();
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

          final polylinePoints =
              points.map((p) => LatLng(p.lat, p.lng)).toList();

          final center = polylinePoints.first;

          return FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              PolylineLayer(polylines: [
                Polyline(
                    points: polylinePoints,
                    color: Colors.blue,
                    strokeWidth: 4.0)
              ]),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}
