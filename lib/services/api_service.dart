import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/delivery_point.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<List<DeliveryPoint>> fetchPoints() async {
    final uri = Uri.parse('$baseUrl/points');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body) as List<dynamic>;
        return data
            .map((e) => DeliveryPoint.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        return _mockPoints();
      }
    } catch (e) {
      // on error return mock points so app is usable offline
      return _mockPoints();
    }
  }

  List<DeliveryPoint> _mockPoints() {
    return [
      DeliveryPoint(
          id: '1', name: 'Start', lat: 52.2297, lng: 21.0122, order: 0),
      DeliveryPoint(
          id: '2', name: 'Stop A', lat: 52.2300, lng: 21.0150, order: 1),
      DeliveryPoint(
          id: '3', name: 'Stop B', lat: 52.2310, lng: 21.0180, order: 2),
      DeliveryPoint(
          id: '4', name: 'End', lat: 52.2320, lng: 21.0200, order: 3),
    ];
  }
}
