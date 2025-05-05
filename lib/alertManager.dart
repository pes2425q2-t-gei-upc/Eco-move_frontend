import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Alert {
  final int id;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final bool isActive;
  final String timestamp;

  Alert({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    required this.isActive,
    required this.timestamp,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id_emergencia'],
      title: json['titol'],
      description: json['descripcio'],
      lat: json['lat'],
      lng: json['lng'],
      isActive: json['is_active'],
      timestamp: json['timestamp'],
    );
  }
}

class AlertManager with ChangeNotifier {
  final String baseUrl = "https://eco-move-backend.onrender.com/api/alerts/polling_alertes/";
  List<Alert> _alerts = [];
  int? _lastTimestamp;

  List<Alert> get alerts => _alerts;

  Future<void> fetchAlerts(double lat, double lng) async {
    try {
      final queryParams = {
        'lat': lat.toString(),
        'lng': lng.toString(),
        if (_lastTimestamp != null) 'since': _lastTimestamp.toString(),
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse the alerts
        final List<dynamic> alertData = data['alerts'];
        _alerts = alertData.map((alertJson) => Alert.fromJson(alertJson)).toList();

        // Update the last timestamp
        _lastTimestamp = data['timestamp'].toInt();

        notifyListeners();
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch alerts: $e");
    }
  }
}