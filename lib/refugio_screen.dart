import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

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
      'http://127.0.0.1:8000/api_punts_carrega/refugios/${widget.idRefugio}/',
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
        title: const Text('Detalles del Refugio'),
        backgroundColor: Colors.green,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : refugio == null
              ? const Center(child: Text('No se pudo cargar el refugio'))
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
                            refugio!['nombre'] ?? 'Nombre desconocido',
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
                                'Dirección: ${refugio!['direccio'] ?? 'N/A'}, ${refugio!['numero_calle'] ?? ''}',
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
                              'Latitud: ${refugio!['lat'] ?? 'N/A'}',
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
                              'Longitud: ${refugio!['lng'] ?? 'N/A'}',
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
                            label: const Text(
                              'Ver en el mapa',
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
