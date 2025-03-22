import 'package:eco_move_frontend/edit_booking.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Booking {
  final String estacion;
  final String fecha;
  final String hora;
  final String duracion;

  Booking({
    required this.estacion,
    required this.fecha,
    required this.hora,
    required this.duracion,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      estacion: json['estacion'],
      fecha: json['fecha'],
      hora: json['hora'],
      duracion: json['duracion'],
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BookingsScreen(),
    );
  }
}

class BookingsScreen extends StatefulWidget {
  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late Future<List<Booking>> futureBookings;

  @override
  void initState() {
    super.initState();
    futureBookings = fetchBookings();
  }

  Future<List<Booking>> fetchBookings() async {
    final url = Uri.parse('http://10.0.2.2:8000/api_punts_carrega/reservas/');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    return Scaffold(
      appBar: AppBar(title: Text("Mis reservas")),
      body: FutureBuilder<List<Booking>>(
        future: futureBookings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay reservas disponibles.'));
          } else {
            final bookings = snapshot.data!;
            return Scrollbar(
              controller: scrollController,
              thickness: 8,
              radius: Radius.circular(10),
              thumbVisibility: true,
              child: ListView.builder(
                controller: scrollController,
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return Card(
                    color: Color(0xfff0daeb),
                    elevation: 10,
                    margin: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(booking.estacion),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fecha: ${booking.fecha}'),
                              Text('Hora: ${booking.hora}'),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EditChargerScreen(
                                      date: booking.fecha,
                                      hour: booking.hora,
                                      duration: booking.duracion,
                                    ),
                                  ),
                                );
                              },
                              child: Text("Editar"),
                            ),
                            TextButton(
                              onPressed: () {
                              },
                              child: Text("Eliminar"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
