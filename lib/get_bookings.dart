import 'package:eco_move_frontend/edit_booking.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'edit_booking.dart';

// Define Booking class
class Booking {
  final String adress;
  final String date;
  final String hour;
  final String duration;

  Booking({required this.adress, required this.date, required this.hour, required this.duration});

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      adress: json['direccion'],
      date: json['data'],
      hour: json['hora'],
      duration: json['duracion']
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

class BookingsScreen extends StatelessWidget {
  // JSON string containing booking data
  final String jsonString = '''
  [
    {"direccion": "Plaça Espanya", "data": "2025-03-14", "hora": "10:30", "duracion" : "30 minutos"},
    {"direccion": "Plaça Catalunya", "data": "2025-03-15", "hora": "12:00", "duracion" : "30 minutos"},
    {"direccion": "Avinguda Barcelona", "data": "2025-03-16", "hora": "13:00", "duracion" : "30 minutos"},
    {"direccion": "Edifici vertex, UPC", "data": "2025-03-17", "hora": "14:00", "duracion" : "30 minutos"}
  ]
  ''';

  @override
  Widget build(BuildContext context) {
    // Decode the JSON string into a list of bookings
    List<dynamic> jsonList = jsonDecode(jsonString);
    List<Booking> bookings = jsonList.map((json) => Booking.fromJson(json)).toList();

    final ScrollController scrollController = ScrollController();

    return Scaffold(
      appBar: AppBar(
        title: Text("Mis reservas"),
      ),
      body: Scrollbar(
        controller: scrollController,
          thickness: 8,
          radius: Radius.circular(10), // Round edges
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
                            title: Text(booking.adress),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Data: ${booking.date}'),
                                Text('Hora: ${booking.hour}')
                              ],
                            )
                        ),
                        Row(
                          children: [
                            TextButton(
                                onPressed: (){
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => EditChargerScreen(
                                        date: booking.date,
                                        hour: booking.hour,
                                        duration: booking.duration,
                                      ),
                                    ),
                                  );
                                },
                                child: Text("Editar")),
                            TextButton(
                                onPressed: (){},
                                child: Text("Eliminar"))
                          ],
                        )

                      ]
                  )
              );
            },
          ),
      )

    );
  }
}
