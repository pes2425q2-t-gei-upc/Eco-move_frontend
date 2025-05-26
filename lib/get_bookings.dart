import 'package:eco_move_frontend/edit_booking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:intl/intl.dart';
import 'calendar.dart';

class Booking {
  final String estacion;
  final String fecha;
  final String hora;
  final String duracion;
  final int id;
  String? direccion; // Add this field to store the address

  Booking({
    required this.estacion,
    required this.fecha,
    required this.hora,
    required this.duracion,
    required this.id,
    this.direccion,
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

  // Helper method to parse date safely
  DateTime get parsedDate {
    try {
      // Handle DD/MM/YYYY format
      if (fecha.contains('/')) {
        final parts = fecha.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );
        }
      }
      // Fallback to standard parsing
      return DateTime.parse(fecha);
    } catch (e) {
      // Return current date as fallback
      return DateTime.now();
    }
  }

  // Helper method to format date for display
  String get formattedDate {
    try {
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return fecha; // Return original if formatting fails
    }
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
  Future<List<Booking>>? futureBookings;
  List<Booking> allBookings = [];
  List<Booking> filteredBookings = [];

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  String? token = '';
  String _searchQuery = '';
  bool _isLoading = false;

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    token = await getAccessToken();
    try {
      final bookings = await fetchBookings();
      setState(() {
        allBookings = bookings;
        filteredBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Booking>> fetchBookings() async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.reservas));
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        List<Booking> bookings = jsonList.map((json) => Booking.fromJson(json)).toList();

        // Fetch addresses for all bookings
        for (Booking booking in bookings) {
          booking.direccion = await _fetchAdress(booking.estacion);
        }

        return bookings;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<String> _fetchAdress(String id) async {
    final url = Uri.parse(
      FrontendRoutes.build(
        FrontendRoutes.estacion(id),
      ),
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        Map<String, dynamic> data = jsonDecode(decodedResponse);
        return data['direccio'] ?? 'Dirección no disponible';
      } else {
        print('Error: Received status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error during HTTP request: $e');
    }
    return 'Dirección no disponible';
  }

  void _filterBookings(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        filteredBookings = allBookings;
      } else {
        filteredBookings = allBookings.where((booking) {
          return (booking.direccion?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
              booking.estacion.toLowerCase().contains(query.toLowerCase()) ||
              booking.fecha.contains(query) ||
              booking.hora.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _refreshBookings() async {
    await _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
           Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: Text(
          context.loc.home_my_reservations,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xff4a7c59),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshBookings,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: _filterBookings,
                  decoration: InputDecoration(
                    hintText: context.loc.search_booking,
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xff4a7c59), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              // Bookings Count
              if (!_isLoading)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '${filteredBookings.length} reserva${filteredBookings.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Bookings List
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.green))
                    : filteredBookings.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                  onRefresh: _refreshBookings,
                  color: Color(0xff4a7c59),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      return _buildBookingCard(booking);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookingCalendarPage(),
            ),
          );
        },
        child: const Icon(Icons.calendar_month),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No tienes reservas'
                : 'No se encontraron reservas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Cuando hagas una reserva aparecerá aquí'
                : 'Intenta con otros términos de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with station info
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff4a7c59),Color(0xff4a7c59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.ev_station,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.direccion ?? 'Cargando dirección...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (booking.direccion != null)
                        Text(
                          'ID: ${booking.estacion}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Booking details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        Icons.calendar_today,
                        context.loc.common_date,
                        booking.formattedDate,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailItem(
                        Icons.access_time,
                        context.loc.common_hour,
                        booking.hora,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildDetailItem(
                  Icons.timer,
                  context.loc.common_duration,
                  '${booking.duracion} hora${booking.duracion != '1' ? 's' : ''}',
                ),
                SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editBooking(booking),
                        icon: Icon(Icons.edit, size: 18),
                        label: Text(context.loc.reservations_edit),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[600],
                          side: BorderSide(color: Colors.blue[600]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => deleteBooking(booking.id),
                        icon: Icon(Icons.delete, size: 18),
                        label: Text(context.loc.reservations_delete),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _editBooking(Booking booking) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditChargerScreen(
          date: booking.fecha,
          hour: booking.hora,
          duration: booking.duracion,
          id: booking.id,
          estacion: booking.estacion,
        ),
      ),
    );

    // Refresh bookings after editing
    if (result != null) {
      await _refreshBookings();
    }
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
        _showDialog(
          context.loc.dialog_success_delete_reseervation,
          isSuccess: true,
        );
        await _refreshBookings(); // Refresh the list
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
}