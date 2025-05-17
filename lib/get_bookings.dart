import 'package:eco_move_frontend/edit_booking.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';

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
    final url = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.reservas),
    );
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
      appBar: AppBar(title: Text(context.loc.home_my_reservations)),
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
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green, // Borde verde para el día actual
                  width: 2,
                ),
              ),
              todayTextStyle: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green.withAlpha(
                  127,
                ), // Reemplazado withOpacity(0.5) con withAlpha(127)
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  final booking =
                      events.first as Booking; // Toma el primer evento
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green, // Fondo verde
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Reserva', // Cambiado para que solo diga "Reserva"
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
                  return Center(
                    child: Text(context.loc.reservations_none_for_this_day),
                  );
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
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.ev_station,
                                    color: Colors.green,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Estación: ${booking.estacion}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Divider(color: Colors.grey[300]),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Fecha: ${booking.fecha}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    'Hora: ${booking.hora}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Duración: ${booking.duracion} horas',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
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
                                    icon: Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.white,
                                    ), // Ícono blanco
                                    label: Text(
                                      context.loc.reservations_edit,
                                      style: TextStyle(
                                        color: Colors.white,
                                      ), // Texto blanco
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      deleteBooking(booking.id);
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: Colors.white,
                                    ), // Ícono blanco
                                    label: Text(
                                      context.loc.reservations_delete,
                                      style: TextStyle(
                                        color: Colors.white,
                                      ), // Texto blanco
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
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
      FrontendRoutes.build(FrontendRoutes.reservasEliminar(id)),
    );
    bool? confirmDelete = await _showConfirmationDialog();
    if (confirmDelete == true) {
      try {
        final response = await http.delete(
          url,
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode == 200) {
          _showDialog(
            context.loc.dialog_success_delete_reseervation,
            isSuccess: true,
          );
          final allBookings = await futureBookings;
          _updateReservasDelDia(selectedDay, allBookings); // Refresh list
        } else if (response.statusCode == 404) {
          _showDialog(
            context.loc.dialog_reservation_not_found,
            isSuccess: false,
          );
        } else {
          _showDialog(
            context.loc.dialog_error_delete_reservation,
            isSuccess: false,
          );
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
          title: Text(context.loc.common_confirmation),
          content: Text(context.loc.dialog_confirm_delete_reservation),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(context.loc.common_cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(context.loc.reservations_delete),
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
          title: Text(isSuccess ? context.loc.common_success : 'Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.loc.common_accept),
            ),
          ],
        );
      },
    );
  }
}
