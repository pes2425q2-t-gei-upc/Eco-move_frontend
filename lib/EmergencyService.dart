import 'dart:convert';
import 'dart:async';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart'; // Asegúrate de importar latlong2

class EmergencyPoint {
  final int id;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String timestamp;
  final String sender;

  EmergencyPoint({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    required this.timestamp,
    required this.sender,
  });

  factory EmergencyPoint.fromJson(Map<String, dynamic> json) {
    return EmergencyPoint(
      id: json['id_emergencia'],
      title: json['titol'],
      description: json['descripcio'],
      lat: json['lat'],
      lng: json['lng'],
      timestamp: json['timestamp'],
      sender: json['sender_email'],
    );
  }
}

class EmergencyService {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  List<EmergencyPoint> _previousPoints = []; // Almacena los puntos anteriores
  bool _isFirstPoll = true;

  Future<String?> _getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  Future<void> _refreshToken(String refreshToken) async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.tokenRefresh));
    final Map<String, dynamic> data = {'refresh': refreshToken};

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> resp = json.decode(response.body);
      await _secureStorage.write(key: 'access', value: resp['access']);
    } else {
      throw Exception('Failed to refresh token');
    }
  }

  Future<List<EmergencyPoint>> fetchEmergencyPoints(double lat, double lng) async {
    final token = await _getAccessToken();

    if (token == null) {
      throw Exception('Authentication token not available');
    }

    final queryParams = {
      'lat': lat.toString(),
      'lng': lng.toString(),
    };

     // Construye correctamente la URI usando AppConfig.prodBaseUrl
  final uri = Uri.parse(FrontendRoutes.build(FrontendRoutes.alertsPollingAlertes)).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> pointsData = data['alerts'];
        return pointsData.map((json) => EmergencyPoint.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        final refreshToken = await _secureStorage.read(key: 'refresh');
        if (refreshToken != null) {
          await _refreshToken(refreshToken);
          return fetchEmergencyPoints(lat, lng); // Retry after refreshing token
        } else {
          throw Exception('Authentication required');
        }
      } else if (response.statusCode == 404) {
        throw Exception("Endpoint not found (404). Check the URL or backend configuration.");
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch emergency points: $e");
    }
  }

  Stream<EmergencyPoint?> pollForNewEmergencyPoints(double lat, double lng, {Duration interval = const Duration(seconds: 20)}) async* {
    while (true) {
      try {
        final newPoints = await fetchEmergencyPoints(lat, lng);

        if (_isFirstPoll) {
          _previousPoints = newPoints;
          _isFirstPoll = false;
        } else {
          // Compara los nuevos puntos con los anteriores
          for (final point in newPoints) {
            if (!_previousPoints.any((p) => p.id == point.id)) {
              yield point; // Devuelve el nuevo punto detectado
            }
          }
          _previousPoints = newPoints; // Actualiza los puntos anteriores
        }
      } catch (e) {
        print("Error during polling: $e");
      }

      await Future.delayed(interval);
    }
  }

   Stream<EmergencyPoint?> pollForNewEmergencyPointsStream(
      LatLng? Function() getPosition,
      {Duration interval = const Duration(seconds: 10)}) async* {
    while (true) {
      try {
        final position = getPosition();
        if (position == null) {
          print("Posición no disponible para el polling.");
        } else {
          final newPoints = await fetchEmergencyPoints(position.latitude, position.longitude);

          if (_isFirstPoll) {
            _previousPoints = newPoints;
            _isFirstPoll = false;
          } else {
            for (final point in newPoints) {
              if (!_previousPoints.any((p) => p.id == point.id)) {
                print("Nuevo punto detectado: ${point.title}");
                yield point;
              }
            }
            _previousPoints = newPoints;
          }
        }
      } catch (e) {
        print("Error durante el polling: $e");
      }

      await Future.delayed(interval);
    }
  }
}
