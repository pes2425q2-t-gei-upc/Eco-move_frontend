import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:eco_move_frontend/routes/frontend_routes.dart';

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
  bool _isLoading = false;

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  String? token = '';

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  @override
  void initState() {
    super.initState();
    _initialize(); // just call the async function
  }

  Future<void> _initialize() async {
    token = await getAccessToken();
    print('Token: $token'); // token should now be available
    if (token != null && token!.isNotEmpty) {
      _selectedDay = _focusedDay;
      _fetchBookings(_selectedDay!); // move this here, after token is ready
    } else {
      // handle token being null or empty
      print('Token is null or empty');
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
          '${FrontendRoutes.apiBase}}/api_punts_carrega/reservas/?dia=$formattedDate',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
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
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xE278A879), width: 3),
                color: Colors.transparent,
              ),
              todayTextStyle: const TextStyle(
                color: Colors.black, // same color as border so it matches
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xE278A879),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _bookings.isEmpty
                    ? const Center(child: Text('No hay reservas para este dia'))
                    : ListView.builder(
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        return Card(
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
                        );
                      },
                    ),
          ),
        ],
      ),
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
          '${FrontendRoutes.apiBase}}/api_punts_carrega/estacions/${station}/',
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
