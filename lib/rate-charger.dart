import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rating App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const RatingScreen(idStation: '46391170'),
    );
  }
}

class RatingScreen extends StatefulWidget {
  final String? idStation;
  const RatingScreen({super.key, required this.idStation});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  Map<String, dynamic> stationData = {};
  Map<String, dynamic> userData = {};
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStation(); // Fetch data when the widget is initialized
  }

  Future<void> _fetchStation() async {
    final url = Uri.parse(
      'http://10.0.2.2:8000/api_punts_carrega/estacions/${widget.idStation}/', // Ensure this URL is correct
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        Map<String, dynamic> data = jsonDecode(decodedResponse);

        setState(() {
          stationData = data;
        });
      } else {
        print('Error: Received status code ${response.statusCode}');  // Print error if status code isn't 200
      }
    } catch (e) {
      print('Error during HTTP request: $e');  // Catch any errors during the request
    }
  }

  Future<void> _fetchUser() async {
    final url = Uri.parse(
      'http://10.0.2.2:8000/api_punts_carrega/usuari/1/', // Ensure this URL is correct
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        Map<String, dynamic> data = jsonDecode(decodedResponse);

        setState(() {
          userData = data;
        });
      } else {
        print('Error: Received status code ${response.statusCode}');  // Print error if status code isn't 200
      }
    } catch (e) {
      print('Error during HTTP request: $e');  // Catch any errors during the request
    }
  }




  Future<void> sendRating() async {
    final url = Uri.parse('http://10.0.2.2:8000/api_punts_carrega/valoraciones_estaciones/');

    final Map<String, dynamic> data = {
      'estacion': widget.idStation,
      'usuario': 1,
      'puntuacion': _rating,
      'comentario': _commentController.text,
    };
  print(data);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        print('Reservation created successfully');
      } else {
        print('Failed to create reservation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valorar estación de carga'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start (left)
          children: [
            // Station info at top left
            SizedBox(height: 40),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.ev_station, color: Color(0xE278A879)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estación: ${stationData['direccio'] ?? "No disponible"}',
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_city, color: Color(0xE278A879)),
                        SizedBox(width: 8),
                        Text(
                          'Ciudad: ${stationData['ciutat'] ?? "No disponible"}',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),


            // Spacer
            SizedBox(height: 100),

            // Rating section centered
            Center(
              child: Column(
                children: [
                  const Text(
                    'Valora la estación de carga:',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  RatingBar(
                    rating: _rating,
                    onRatingChanged: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _rating > 0 ? 'Tu valoración: $_rating de 5' : 'Por favor, valora la estación',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Añade un comentario:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _commentController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Escribe tu opinión sobre esta estación...',
                            filled: false,
                          ),
                          validator: (value) {
                            if (_rating == 0) {
                              return 'Por favor, selecciona una valoración';
                            }
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, añade un comentario';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_rating > 0)
                    ElevatedButton(
                      onPressed: () {
                        sendRating();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Valoración $_rating enviada correctamente')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xE278A879),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Enviar valoración'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RatingBar extends StatelessWidget {
  final int rating;
  final Function(int) onRatingChanged;

  const RatingBar({
    Key? key,
    required this.rating,
    required this.onRatingChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 40,
          ),
          onPressed: () {
            onRatingChanged(index + 1);
          },
        );
      }),
    );
  }
}