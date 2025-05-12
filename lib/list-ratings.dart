// main.dart
import 'package:eco_move_frontend/config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Charger Ratings',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ListRatingsScreen(idStation: '12345'), // Reemplaza '12345' con el ID real de la estación
    );
  }
}

class ListRatingsScreen extends StatefulWidget {
  final String idStation;

  const ListRatingsScreen({Key? key, required this.idStation}) : super(key: key);

  @override
  _RatingsScreenState createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<ListRatingsScreen> {
  List<dynamic> ratings = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchRatings();
  }

  Future<void> fetchRatings() async {
  setState(() {
    isLoading = true;
    error = '';
  });

  try {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBase}/api_punts_carrega/estacions/${widget.idStation}/valoraciones/'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        ratings = data;
        isLoading = false;
      });
    } else {
      setState(() {
        error = 'Failed to load ratings: ${response.statusCode}';
        isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      error = 'Error: $e';
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charger Ratings'),
      ),
      body: RefreshIndicator(
        onRefresh: fetchRatings,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchRatings,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (ratings.isEmpty) {
      return const Center(child: Text('No ratings available'));
    }

    return ListView.builder(
      itemCount: ratings.length,
      itemBuilder: (context, index) {
        final rating = ratings[index];
        return RatingCard(
          username: rating['username'] ?? 'Anónimo',
          rating: rating['puntuacion']?.toString() ?? 'Sin puntuación',
          comment: rating['comentario'] ?? 'Sin comentarios',
        );
      },
    );
  }
}

class RatingCard extends StatelessWidget {
  final String username;
  final String rating;
  final String comment;

  const RatingCard({
    Key? key,
    required this.username,
    required this.rating,
    required this.comment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment),
          ],
        ),
      ),
    );
  }
}