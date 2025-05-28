import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';

class RefugioScreen extends StatefulWidget {
  final String idRefugio;
  final double? distanciaKm;

  const RefugioScreen({Key? key, required this.idRefugio, this.distanciaKm}) : super(key: key);

  @override
  State<RefugioScreen> createState() => _RefugioScreenState();
}

class _RefugioScreenState extends State<RefugioScreen> {
  Map<String, dynamic>? refugio;
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchRefugio();
  }

  Future<void> _fetchRefugio() async {
    final url = Uri.parse(
        'http://nattech.fib.upc.edu:40430/api/refugios/${widget.idRefugio}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
         final decodedResponse = utf8.decode(response.bodyBytes);
        setState(() {
          refugio = json.decode(decodedResponse);
          _isLoading = false;
          _errorMsg = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMsg = context.loc.shelter_error_loading(response.statusCode.toString());
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = context.loc.shelter_error_request(e.toString());
      });
    }
  }

  Future<void> _openGoogleMaps(String latitude, String longitude) async {
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
  final Color azulRefugio = Colors.lightBlueAccent;
  final isSmallScreen = MediaQuery.of(context).size.width < 350;

  return Scaffold(
    appBar: AppBar(
      title: Text(context.loc.shelter_shelter_details),
      backgroundColor: azulRefugio,
      foregroundColor: Colors.white,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMsg != null
          ? Center(
              child: Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : refugio == null
              ? Center(
                  child: Text(context.loc.shelter_shelter_could_not_be_loaded),
                )
              : Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 8.0 : 24.0),
                  child: ListView(
                    children: [
                      Center(
                        child: Text(
                          refugio!['nombre'] ??
                              context.loc.shelter_shelter_unknown_name,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 22,
                            fontWeight: FontWeight.bold,
                            color: azulRefugio,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: azulRefugio),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${context.loc.station_address}: ${refugio!['direccion'] ?? 'N/A'}, ${refugio!['numero_calle'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.distanciaKm != null) ...[
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(Icons.directions_walk, color: azulRefugio),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${context.loc.shelter_distance}: ${widget.distanciaKm!.toStringAsFixed(2)} m',
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (refugio != null &&
                                refugio!['latitud'] != null &&
                                refugio!['longitud'] != null) {
                             await  _openGoogleMaps(
                                refugio!['latitud'],
                                refugio!['longitud'],
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.directions,
                            color: Colors.white,
                          ),
                          label: Text(
                            context.loc.how_to_arrive,
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azulRefugio,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 24,
                              vertical: isSmallScreen ? 8 : 14,
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
      );
    }
}
