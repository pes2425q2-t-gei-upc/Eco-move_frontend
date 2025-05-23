import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'routes/frontend_routes.dart';

class BiciReservasScreen extends StatefulWidget {
  const BiciReservasScreen({super.key});

  @override
  State<BiciReservasScreen> createState() => _BiciReservasScreenState();
}

class _BiciReservasScreenState extends State<BiciReservasScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  List<dynamic> reservas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReservas();
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  Future<void> fetchReservas() async {
    final token = await getAccessToken();
    if (token == null) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token no disponible')),
      );
      return;
    }

    final url = Uri.parse(
      FrontendRoutes.build('/api/bicing/reservas/mis_reservas/'),
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          reservas = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas de Bicis'),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reservas.isEmpty
              ? const Center(child: Text('No tienes reservas'))
              : ListView.builder(
                  itemCount: reservas.length,
                  itemBuilder: (context, index) {
                    final reserva = reservas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: reserva.entries.map<Widget>((entry) {
                            return Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(fontSize: 16),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}