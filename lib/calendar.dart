import 'package:eco_move_frontend/edit_booking.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Booking Calendar',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const BookingCalendarPage(),
    );
  }
}

class BookingCalendarPage extends StatefulWidget {
  const BookingCalendarPage({super.key});

  @override
  _BookingCalendarPageState createState() => _BookingCalendarPageState();
}

class _BookingCalendarPageState extends State<BookingCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Booking> _bookings = [];
  Map<DateTime, List<Booking>> _monthlyBookings = {};
  bool _isLoading = false;

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  String? token = '';

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    token = await getAccessToken();
    print('Token: $token');
    if (token != null && token!.isNotEmpty) {
      _selectedDay = _focusedDay;
      await _fetchMonthlyBookings(_focusedDay);
      _fetchBookings(_selectedDay!);
    } else {
      print('Token is null or empty');
    }
  }

  Future<void> _fetchMonthlyBookings(DateTime month) async {
    try {
      // Get first and last day of the month
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      Map<DateTime, List<Booking>> monthlyBookings = {};

      // Fetch bookings for each day of the month
      for (int day = 1; day <= lastDay.day; day++) {
        final currentDate = DateTime(month.year, month.month, day);
        final formattedDate = "${currentDate.day.toString().padLeft(2, '0')}/${currentDate.month.toString().padLeft(2, '0')}/${currentDate.year}";

        try {
          final response = await http.get(
            Uri.parse(
              FrontendRoutes.build(FrontendRoutes.reservasDia(formattedDate)),
            ),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);
            if (data.isNotEmpty) {
              final bookings = await Future.wait(
                data.map((item) => Booking.fromJson(item)),
              );
              monthlyBookings[DateTime(currentDate.year, currentDate.month, currentDate.day)] = bookings;
            }
          }
        } catch (e) {
          print('Error fetching bookings for $formattedDate: $e');
        }
      }

      setState(() {
        _monthlyBookings = monthlyBookings;
      });
    } catch (e) {
      print('Error fetching monthly bookings: $e');
    }
  }

  Future<void> _fetchBookings(DateTime day) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final formattedDate =
          "${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}";
      final response = await http.get(
        Uri.parse(
          FrontendRoutes.build(FrontendRoutes.reservasDia(formattedDate)),
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final bookings = await Future.wait(
          data.map((item) => Booking.fromJson(item)),
        );
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      } else {
        setState(() {
          _bookings = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bookings for $formattedDate')),
        );
      }
    } catch (e) {
      setState(() {
        _bookings = [];
        _isLoading = false;
      });
      print('Error esta aqui: ${e.toString()}');
    }
  }

  List<Booking> _getBookingsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _monthlyBookings[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      body: Column(
        children: [
          TableCalendar<Booking>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getBookingsForDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _fetchBookings(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _fetchMonthlyBookings(focusedDay);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xE278A879), width: 3),
                color: Colors.transparent,
              ),
              todayTextStyle: const TextStyle(
                color: Colors.black,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xE278A879),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: Color(0xE278A879),
                shape: BoxShape.circle,
              ),
              markerMargin: const EdgeInsets.symmetric(horizontal: 1.5),
              markersAlignment: Alignment.bottomCenter,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Color(0xE278A879),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const Divider(),
          Expanded(
            child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bookings.isEmpty
                ? Center(child: Text(context.loc.no_bookings))
                : ListView.builder(
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                return InkWell(
                    onTap: () => showStationDialog(context: context, station: booking.station, startTime: booking.startTime, duration: booking.duration, date: booking.date, id: booking.id),
                    child: Card(
                      color: Color(0xFFF0FFF0),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        title: Text(booking.station),
                        subtitle: Text(
                          '${booking.date}\n${booking.startTime}',
                        ),
                      ),
                    )
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showStationDialog({
    required BuildContext context,
    required String station,
    required String startTime,
    required String duration,
    required String date,
    required int id
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Station Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Station:', station),
              SizedBox(height: 8),
              _buildDetailRow('Start Time:', startTime),
              SizedBox(height: 8),
              _buildDetailRow('Duration:', duration),
              SizedBox(height: 8),
              _buildDetailRow('Date:', date),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                      builder: (context) => EditChargerScreen(date : date, hour: startTime, duration: duration, id: id, estacion: station)
                  ),
                );
              },
              child: Text(
                'Edit',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () async {
                await deleteBooking(id);
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text(context.loc.common_confirmation),
            ],
          ),
          content: Text(context.loc.dialog_confirm_delete_reservation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.loc.common_cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(context.loc.reservations_delete),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteBooking(int id) async {
    final url = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.reservasEliminar(id)),
    );

    bool? confirmDelete = await _showConfirmationDialog();
    if (confirmDelete != true) return;

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // Close the station details dialog first
        Navigator.of(context).pop();

        // Show success message
        _showDialog(
          context.loc.dialog_success_delete_reseervation,
          isSuccess: true,
        );

        // Refresh the bookings list and monthly bookings
        if (_selectedDay != null) {
          await _fetchBookings(_selectedDay!);
          await _fetchMonthlyBookings(_focusedDay);
        }
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

  void _showDialog(String message, {required bool isSuccess}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              SizedBox(width: 8),
              Text(isSuccess ? context.loc.common_success : 'Error'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(context.loc.common_accept),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class Booking {
  final int id;
  final String station;
  final String date;
  final String startTime;
  final String duration;

  Booking({
    required this.id,
    required this.station,
    required this.startTime,
    required this.duration,
    required this.date,
  });

  static Future<String?> _fetchStation(String station) async {
    try {
      final response = await http.get(
        Uri.parse(
          FrontendRoutes.build(FrontendRoutes.estacion(station)),
        ),
      );
      if (response.statusCode == 200) {
        final utf8Decoded = utf8.decode(response.bodyBytes);
        Map<String, dynamic> jsonList = jsonDecode(utf8Decoded);
        return jsonList['direccio'];
      }
    } catch (e) {
      print('Error fetching station: $e');
    }
    return null;
  }

  static Future<Booking> fromJson(Map<String, dynamic> json) async {
    String stationId = json['estacion'];
    String? dir = await _fetchStation(stationId);

    return Booking(
      id: json['id'],
      station: dir ?? 'Unknown',
      startTime: json['hora'],
      duration: json['duracion'],
      date: json['fecha'],
    );
  }
}