class DeliveryPoint {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int order;

  DeliveryPoint({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.order,
  });

  factory DeliveryPoint.fromJson(Map<String, dynamic> json) {
    return DeliveryPoint(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      order: (json['order'] ?? 0) as int,
    );
  }
}
