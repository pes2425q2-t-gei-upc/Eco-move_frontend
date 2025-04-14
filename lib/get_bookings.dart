import 'package:eco_move_frontend/edit_booking.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Importa el paquete intl

import 'package:table_calendar/table_calendar.dart';

class Booking {
  final String estacion;
  final String fecha;
  final String hora;
  final String duracion;
  final int id;

  Booking({
    required this.estacion,
    required this.fecha,
    required this.hora,
    required this.duracion,
    required this.id,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      estacion: json['estacion'],
      fecha: json['fecha'],
      hora: json['hora'],
      duracion: json['duracion'],
      id: json['id'],
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: BookingsScreen());
  }
}

class BookingsScreen extends StatefulWidget {
  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late Future<List<Booking>> futureBookings;
  List<Booking> reservasDelDia = [];
  Map<DateTime, List<Booking>> eventos = {}; // Mapa de eventos

  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    futureBookings = fetchBookings();
    futureBookings.then((bookings) {
      _populateEventos(bookings); // Actualiza el mapa de eventos
    });
  }

  Future<List<Booking>> fetchBookings() async {
    final url = Uri.parse('http://127.0.0.1:8000/api_punts_carrega/reservas/');
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

  void _populateEventos(List<Booking> bookings) {
    setState(() {
      eventos = {};
      for (var booking in bookings) {
        final bookingDate = DateTime.parse(booking.fecha);
        final normalizedDate = DateTime(
          bookingDate.year,
          bookingDate.month,
          bookingDate.day,
        ); // Normaliza la fecha
        if (eventos[normalizedDate] == null) {
          eventos[normalizedDate] = [];
        }
        eventos[normalizedDate]!.add(booking);
      }
    });
  }

  void _updateReservasDelDia(DateTime day, List<Booking> allBookings) {
    setState(() {
      reservasDelDia =
          allBookings.where((booking) {
            final bookingDate = DateTime.parse(booking.fecha);
            return bookingDate.year == day.year &&
                bookingDate.month == day.month &&
                bookingDate.day == day.day;
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    return Scaffold(
      appBar: AppBar(title: Text("Mis reservas")),
      body: Column(
        children: [
          TableCalendar(
            locale: 'en_US',
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) async {
              setState(() {
                this.selectedDay = selectedDay;
                this.focusedDay = focusedDay;
              });
              final allBookings = await futureBookings;
              _updateReservasDelDia(selectedDay, allBookings);
            },
            eventLoader: (day) {
              final normalizedDay = DateTime(
                day.year,
                day.month,
                day.day,
              ); // Normaliza la fecha
              return eventos[normalizedDay] ?? [];
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  final booking =
                      events.first as Booking; // Toma el primer evento
                  final formattedHour = DateFormat('HH:mm').format(
                    DateTime.parse('1970-01-01 ${booking.hora}'),
                  ); // Formatea la hora
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green, // Fondo verde
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Reserva: $formattedHour',
                        style: TextStyle(
                          color: Colors.white, // Texto blanco
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return SizedBox.shrink(); // No muestra nada si no hay eventos
              },
            ),
          ),
          // Lista de reservas debajo del calendario
          Expanded(
            child: FutureBuilder<List<Booking>>(
              future: futureBookings,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (reservasDelDia.isEmpty) {
                  return Center(child: Text('No hay reservas para este día'));
                } else {
                  return Scrollbar(
                    controller: scrollController,
                    thickness: 8,
                    radius: Radius.circular(10),
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: reservasDelDia.length,
                      itemBuilder: (context, index) {
                        final booking = reservasDelDia[index];
                        return Card(
                          color: Color(0xffebe8e8),
                          elevation: 5,
                          margin: EdgeInsets.all(10),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text('#${booking.estacion}'),
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
                                    onPressed: () async {
                                      final result = await Navigator.of(
                                        context,
                                      ).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) => EditChargerScreen(
                                                date: booking.fecha,
                                                hour: booking.hora,
                                                duration: booking.duracion,
                                                id: booking.id,
                                                estacion: booking.estacion,
                                              ),
                                        ),
                                      );

                                      // Refresh bookings after editing
                                      final allBookings = await futureBookings;
                                      _updateReservasDelDia(
                                        selectedDay,
                                        allBookings,
                                      );
                                    },
                                    child: Text("Editar"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      deleteBooking(booking.id);
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
          ),
        ],
      ),
    );
  }

  Future<void> deleteBooking(int id) async {
    final url = Uri.parse(
      'https://eco-move-backend.onrender.com/api_punts_carrega/reservas/$id/eliminar/',
    );
    bool? confirmDelete = await _showConfirmationDialog();
    if (confirmDelete == true) {
      try {
        final response = await http.delete(
          url,
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode == 200) {
          _showDialog('Reserva eliminada con éxito', isSuccess: true);
          final allBookings = await futureBookings;
          _updateReservasDelDia(selectedDay, allBookings); // Refresh list
        } else if (response.statusCode == 404) {
          _showDialog('La reserva no existe.', isSuccess: false);
        } else {
          _showDialog('Error al eliminar la reserva.', isSuccess: false);
        }
      } catch (e) {
        _showDialog('Error: $e', isSuccess: false);
      }
    }
  }

  Future<bool?> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmación'),
          content: Text('¿Está seguro de que quiere eliminar la reserva?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _showDialog(String message, {required bool isSuccess}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isSuccess ? 'Éxito' : 'Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}
