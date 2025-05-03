import 'package:eco_move_frontend/edit_booking.dart';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:eco_move_frontend/config.dart';

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
    final url = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.listReservations),
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

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    return Scaffold(
      appBar: AppBar(title: Text(context.loc.home_my_reservations)),
      body: FutureBuilder<List<Booking>>(
        future: futureBookings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(context.loc.reservations_none));
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
                              Text(
                                '${context.loc.common_date}: ${booking.fecha}',
                              ),
                              Text(
                                '${context.loc.common_hour}: ${booking.hora}',
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () async {
                                final result = await Navigator.of(context).push(
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

                                // This is the important part - refresh regardless of result value
                                setState(() {
                                  futureBookings = fetchBookings();
                                });
                              },
                              child: Text(context.loc.reservations_edit),
                            ),
                            TextButton(
                              onPressed: () {
                                deleteBooking(booking.id);
                              },
                              child: Text(context.loc.reservations_delete),
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

  Future<void> deleteBooking(int id) async {
    final url = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.deleteReservation(id)),
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
          setState(() {
            futureBookings = fetchBookings(); // Refrescar la lista
          });
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
