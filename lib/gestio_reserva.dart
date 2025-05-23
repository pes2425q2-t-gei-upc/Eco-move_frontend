import 'dart:convert';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:share_plus/share_plus.dart';
import 'rate-charger.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'calculate_price.dart';
import 'book_charger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:eco_move_frontend/list-ratings.dart';
import 'notificar_error_screen.dart';

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
        FrontendRoutes.estacion(idStation),
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

  Widget _shareTextButton({
    required BuildContext context,
    required double latitude, 
    required double longitude,
    required String stationName,
  }) {
    return TextButton(
      onPressed: () async {
        final mapUrl = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
        final shareMessage = '${context.loc.station_share_message_1}: $stationName\n${context.loc.station_share_message_2}: $mapUrl';

        await Share.shareWithResult(shareMessage);
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.yellow, // Choose your color
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ios_share_rounded, color: Colors.black),
          SizedBox(width: 8),
          Text(context.loc.station_share_station),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Create a reusable method for building buttons
    Widget _buildActionButton({
      required IconData icon,
      required String text,
      required Color backgroundColor,
      required VoidCallback onPressed,
    }) {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 8),
            Text(text),
          ],
        ),
      );
    }

    // Create a reusable method for the info rows
    Widget _buildInfoRow({
      required String label,
      required String value,
      bool expandValue = false,
    }) {
      final labelWidget = Text(
        label,
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );

      final valueWidget = Text(
        value,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
        ),
        overflow: expandValue ? TextOverflow.ellipsis : TextOverflow.clip,
        softWrap: expandValue,
      );

      return Row(
        children: [
          labelWidget,
          const SizedBox(width: 10),
          expandValue ? Expanded(child: valueWidget) : valueWidget,
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Estación ${stationData['direccio'] ?? 'Cargando...'}'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              children: [
            // Charger type info
            _buildInfoRow(
              label: '${context.loc.station_plug_type}: ',
              value: '',
            ),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: (stationData['tipus_carregador'] as List<dynamic>? ?? [])
                        .expand((tipo) => (tipo ?? '').split('+'))
                        .map<Widget>((tipo) => Chip(
                      label: Text(
                        tipo.trim(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ))
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Station power info
            _buildInfoRow(
              label: '${context.loc.station_power}: ',
              value: stationData['potencia'] != null
                  ? '${stationData['potencia']} kW'
                  : 'N/A',
            ),
            const SizedBox(height: 16),

            // Station status info
            _buildInfoRow(
              label: '${context.loc.station_status}: ',
              value: stationData['fuera_de_servicio'] == true
                  ? context.loc.out_of_service ?? 'Out of Service'
                  : (stationData['nplaces'] != null &&
                  int.tryParse(stationData['nplaces'])! > 0
                  ? 'Disponible'
                  : 'Ocupat'),
            ),
            const SizedBox(height: 16),

            // City info
            _buildInfoRow(
              label: '${context.loc.station_city}: ',
              value: stationData['ciutat'] ?? 'No disponible',
              expandValue: true,
            ),


            if (stationData['fuera_de_servicio'] == true) ...[
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.loc.out_of_service ?? 'Out of Service',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                      if (stationData['motivo_fuera_servicio'] != null &&
                                             stationData['motivo_fuera_servicio'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        stationData['motivo_fuera_servicio'].toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      context.loc.station_no_actions_available ?? 'No actions available while station is out of service.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Only show report error button when station is out of service
              const SizedBox(height: 30),
              _buildActionButton(
                icon: Icons.error,
                text: context.loc.station_report_error,
                backgroundColor: Colors.red,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NotificarErrorScreen(idStation: idStation),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _shareTextButton(
                context: context,
                latitude: stationData['lat'],
                longitude: stationData['lng'],
                stationName: stationData['direccio'] ?? 'Cargando...',
              ),
            ] else ...[
              // Show all action buttons when station is not out of service
              const SizedBox(height: 60),

              // Action buttons
              _buildActionButton(
                icon: Icons.location_on,
                text: context.loc.station_how_to_arrive,
                backgroundColor: const Color(0xFF2C8235),
                onPressed: () => _openGoogleMaps(stationData['lat'], stationData['lng']),
              ),
              const SizedBox(height: 16),

              _buildActionButton(
                icon: Icons.money,
                text: context.loc.station_calculate_price,
                backgroundColor: const Color(0xFF54a0e8),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChargeCalculatorScreen(
                        tipoCarga: stationData['tipus_velocitat'],
                        precio: '3 €',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildActionButton(
                icon: Icons.calendar_month,
                text: context.loc.station_reserve,
                backgroundColor: const Color(0xFFa955e0),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BookChargerScreen(idStation: idStation),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildActionButton(
                icon: Icons.star,
                text: context.loc.station_view_reviews,
                backgroundColor: Colors.orangeAccent,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ListRatingsScreen(idStation: idStation),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildActionButton(
                icon: Icons.recommend_sharp,
                text: context.loc.station_give_review,
                backgroundColor: Colors.redAccent,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RatingScreen(idStation: idStation),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildActionButton(
                icon: Icons.error,
                text: context.loc.station_report_error,
                backgroundColor: Colors.red,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NotificarErrorScreen(idStation: idStation),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _shareTextButton(
                context: context,
                latitude: stationData['lat'],
                longitude: stationData['lng'],
                stationName: stationData['direccio'] ?? 'Cargando...',
              ),
            ],
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
