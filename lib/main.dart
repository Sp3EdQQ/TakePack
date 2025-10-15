import 'package:flutter/material.dart';
import 'pages/map_page.dart';
import 'services/api_service.dart';

void main() {
  final api = ApiService(baseUrl: 'http://localhost:3000');
  runApp(TakePackApp(apiService: api));
}

class TakePackApp extends StatelessWidget {
  final ApiService apiService;
  const TakePackApp({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TakePack - Learn Flutter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MapPage(apiService: apiService),
    );
  }
}
