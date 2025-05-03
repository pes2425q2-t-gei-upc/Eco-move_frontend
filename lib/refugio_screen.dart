import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';

class RefugioScreen extends StatefulWidget {
  final String idRefugio;

  const RefugioScreen({Key? key, required this.idRefugio}) : super(key: key);

  @override
  State<RefugioScreen> createState() => _RefugioScreenState();
}

class _RefugioScreenState extends State<RefugioScreen> {
  Map<String, dynamic>? refugio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRefugio();
  }

  Future<void> _fetchRefugio() async {
    final url = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.shelterById(widget.idRefugio)),
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          refugio = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        print('Error al cargar refugio: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error en la solicitud de refugio: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.shelter_shelter_details),
        backgroundColor: Colors.green,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : refugio == null
              ? Center(
                child: Text(context.loc.shelter_shelter_could_not_be_loaded),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            refugio!['nombre'] ??
                                context.loc.shelter_shelter_unknown_name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.green),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${context.loc.station_address}: ${refugio!['direccio'] ?? 'N/A'}, ${refugio!['numero_calle'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const Icon(Icons.map, color: Colors.green),
                            const SizedBox(width: 10),
                            Text(
                              '${context.loc.common_latitude}: ${refugio!['lat'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.map_outlined, color: Colors.green),
                            const SizedBox(width: 10),
                            Text(
                              '${context.loc.common_longitude}: ${refugio!['lng'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (refugio != null &&
                                  refugio!['lat'] != null &&
                                  refugio!['lng'] != null) {
                                _openGoogleMaps(
                                  refugio!['lat'],
                                  refugio!['lng'],
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.directions,
                              color: Colors.white,
                            ),
                            label: Text(
                              context.loc.shelter_view_in_map,
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
