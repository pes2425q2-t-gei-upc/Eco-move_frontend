import 'dart:convert';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'calculate_price.dart';
import 'book_charger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: EstacionScreen(idStation: '46109488'));
  }
}

class EstacionScreen extends StatefulWidget {
  final String idStation;

  const EstacionScreen({required this.idStation, super.key});

  @override
  State<EstacionScreen> createState() =>
      _EstacionScreenState(idStation: idStation);
}

class _EstacionScreenState extends State<EstacionScreen> {
  final String idStation;
  Map<String, dynamic> stationData = {};
  bool isLoading = true; // New flag for loading state

  _EstacionScreenState({required this.idStation});

  Future<void> _fetchStations() async {
    final url = Uri.parse(
      FrontendRoutes.build(
        FrontendRoutes.stationById(idStation),
      ), // Ensure this URL is correct
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        Map<String, dynamic> data = jsonDecode(decodedResponse);

        setState(() {
          stationData = data;
          isLoading = false; // Data is fetched, stop loading
        });
      } else {
        print(
          'Error: Received status code ${response.statusCode}',
        ); // Print error if status code isn't 200
      }
    } catch (e) {
      print(
        'Error during HTTP request: $e',
      ); // Catch any errors during the request
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchStations(); // Fetch data when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estación ${stationData['direccio'] ?? 'Cargando...'}'),
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(),
              ) // Show loading spinner while data is being fetched
              : Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${context.loc.station_plug_type}: ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8.0, // Horizontal spacing between chips
                            runSpacing: 4.0, // Vertical spacing between rows
                            children:
                                (stationData['tipus_carregador']
                                            as List<dynamic>? ??
                                        [])
                                    .expand(
                                      (tipo) => (tipo ?? '').split('+'),
                                    ) // Split by '+'
                                    .map<Widget>(
                                      (tipo) => Chip(
                                        label: Text(
                                          tipo.trim(), // Remove any surrounding whitespace
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '${context.loc.station_power}: ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          stationData['potencia'] != null
                              ? '${stationData['potencia']} kW'
                              : 'N/A',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '${context.loc.station_status}: ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          stationData['nplaces'] != null &&
                                  int.tryParse(stationData['nplaces'])! > 0
                              ? 'Disponible'
                              : 'Ocupat',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '${context.loc.station_city}: ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            stationData['ciutat'] ?? 'No disponible',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                            ),
                            overflow:
                                TextOverflow
                                    .ellipsis, // Handle overflow with ellipsis
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                    TextButton(
                      onPressed:
                          () => _openGoogleMaps(
                            stationData['lat'],
                            stationData['lng'],
                          ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF2C8235),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            13,
                          ), // Rounded corners
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on, color: Colors.white),
                          SizedBox(width: 8),
                          Text(context.loc.station_how_to_arrive),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => ChargeCalculatorScreen(
                                  tipoCarga: stationData['tipus_velocitat'],
                                  precio: '3 €',
                                ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF54a0e8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            13,
                          ), // Rounded corners
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.money, color: Colors.white),
                          SizedBox(width: 8),
                          Text(context.loc.station_calculate_price),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    BookChargerScreen(idStation: idStation),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFa955e0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            13,
                          ), // Rounded corners
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month, color: Colors.white),
                          SizedBox(width: 8),
                          Text(context.loc.station_reserve),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Future<void> _openGoogleMaps(
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$destinationLatitude,$destinationLongitude';
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }
}
