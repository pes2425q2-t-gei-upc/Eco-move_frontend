import 'dart:convert';
import 'package:eco_move_frontend/get_bookings.dart';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:eco_move_frontend/l10n/context_ext.dart';

class EditChargerScreen extends StatelessWidget {
  final String date;
  final String hour;
  final String duration;
  final int id;
  final String estacion;

  const EditChargerScreen({
    super.key,
    required this.date,
    required this.hour,
    required this.duration,
    required this.id,
    required this.estacion,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          context.loc.reservations_book_charger,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: DateTimePickerWithDropdown(date: date, hour: hour, duration: duration, id: id, estacion: estacion,),
        ),
      ),
    );
  }
}

class DateTimePickerWithDropdown extends StatefulWidget {
  final String date;
  final String hour;
  final String duration;
  final int id;
  final String estacion;

  const DateTimePickerWithDropdown({
    super.key,
    required this.date,
    required this.hour,
    required this.duration,
    required this.id,
    required this.estacion,
  });

  @override
  _DateTimePickerWithDropdownState createState() =>
      _DateTimePickerWithDropdownState();
}

class _DateTimePickerWithDropdownState
    extends State<DateTimePickerWithDropdown> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final MaskedTextController _durationController = MaskedTextController(
    mask: '00:00',
  );

  DateTime? _initialDate;
  TimeOfDay? _initialTime;

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  String? token = '';
  int myId = -1;

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // Function to show the date picker
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xff4a7c59),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      String formattedDate =
          "${pickedDate.day.toString().padLeft(2, '0')}/"
          "${pickedDate.month.toString().padLeft(2, '0')}/"
          "${pickedDate.year}";
      setState(() {
        _dateController.text = formattedDate;
      });
    }
  }

  // Function to show the time picker
  Future<void> _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xff4a7c59),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      String formattedTime =
          "${pickedTime.hour.toString().padLeft(2, '0')}:"
          "${pickedTime.minute.toString().padLeft(2, '0')}";
      setState(() {
        _timeController.text = formattedTime;
      });
    }
  }


  bool _isValidDuration(String duration) {
    if (duration.isEmpty) return false;

    final parts = duration.split(':');
    if (parts.length != 2) return false;

    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);

    if (hours == null || minutes == null) return false;
    if (hours < 0 || hours > 23) return false;
    if (minutes < 0 || minutes > 59) return false;
    if (hours == 0 && minutes == 0) return false;

    return true;
  }

  Widget _buildInputCard({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    VoidCallback? onTap,
    bool readOnly = false,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              keyboardType: keyboardType,
              onTap: onTap,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.normal,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xff4a7c59).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xff4a7c59),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xff4a7c59).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.ev_station,
                    color: Color(0xff4a7c59),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book Your Charging Session',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Select date, time and duration',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Date Input
          _buildInputCard(
            label: context.loc.common_date,
            controller: _dateController,
            hint: 'dd/mm/yyyy',
            icon: Icons.calendar_today,
            onTap: _selectDate,
            readOnly: true,
          ),

          // Time Input
          _buildInputCard(
            label: context.loc.common_hour,
            controller: _timeController,
            hint: 'hh:mm',
            icon: Icons.access_time,
            onTap: _selectTime,
            readOnly: true,
          ),

          // Duration Input
          _buildInputCard(
            label: '${context.loc.reservations_duration_hint}',
            controller: _durationController,
            hint: 'hh:mm (e.g., 02:30)',
            icon: Icons.timer,
            keyboardType: TextInputType.number,
          ),

          SizedBox(height: 32),

          // Confirm Button
          Container(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (_dateController.text.isNotEmpty &&
                    _timeController.text.isNotEmpty &&
                    _durationController.text.isNotEmpty &&
                    _isValidDuration(_durationController.text)) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Color(0xff4a7c59),
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                context.loc.edit_booking_confirm_reservation,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        content: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.loc.reservation_confirm_question,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 20),
                              _buildDetailRow(Icons.calendar_today, context.loc.common_date, _dateController.text),
                              _buildDetailRow(Icons.access_time, context.loc.common_hour, _timeController.text),
                              _buildDetailRow(Icons.timer, context.loc.common_duration, _durationController.text),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              context.loc.common_cancel,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Parse the selected date
                              DateTime selectedDate = DateTime.parse(
                                _dateController.text.isEmpty
                                    ? DateTime.now().toString()
                                    : _dateController.text
                                    .split('/')
                                    .reversed
                                    .join('-'),
                              );

                              // Parse the selected time
                              List<String> timeParts = _timeController.text.split(':');
                              TimeOfDay selectedTime = TimeOfDay(
                                hour: int.parse(timeParts[0]),
                                minute: int.parse(timeParts[1]),
                              );

                              DateTime selectedDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );

                              // Check if the selected date and time are valid
                              if (selectedDateTime.isBefore(DateTime.now())) {
                                Navigator.of(context).pop();
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red,
                                            size: 24,
                                          ),
                                          SizedBox(width: 12),
                                          Flexible(
                                            child: Text(
                                              context.loc.reservation_invalid_datetime_title,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Text(
                                        context.loc.reservation_invalid_datetime_message,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      actions: <Widget>[
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xff4a7c59),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(context.loc.common_close),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                editBooking(widget.id, _dateController.text, _timeController.text, _durationController.text, widget.estacion);
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                      builder: (context) => BookingsScreen()
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xff4a7c59),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              context.loc.edit_booking_confirm_reservation,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  String errorMessage = context.loc.edit_booking_missing_field;
                  if (_durationController.text.isNotEmpty && !_isValidDuration(_durationController.text)) {
                    errorMessage = 'Please enter a valid duration (hh:mm format)';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red[400],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff4a7c59),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.loc.edit_booking_confirm_reservation,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Color(0xff4a7c59),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  '$label: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
    _dateController.text = widget.date;
    _timeController.text = widget.hour;
    _durationController.text = widget.duration;

    _initialDate = DateTime.tryParse(widget.date);
    _initialTime = TimeOfDay(
      hour: int.parse(widget.hour.split(":")[0]),
      minute: int.parse(widget.hour.split(":")[1]),
    );

  }

  Future<String?> _fetchStations(String idStation) async {
    final url = Uri.parse(
      FrontendRoutes.build(
        FrontendRoutes.estacion(idStation),
      ),
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        Map<String, dynamic> data = jsonDecode(decodedResponse);
        return data['direccio'];
      } else {
        print('Error: Received status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error during HTTP request: $e');
    }
    return '';
  }

  Future<bool> editBooking(
    int id,
    String date,
    String hour,
    String? duration,
    String estacion,
  ) async {
    final url = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.reservasModificar(id)),
    );

    final Map<String, dynamic> data = {
      'estacion': estacion,
      'fecha': date,
      'hora': hour,
      'duracion': duration,
    };

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        print('Reservation modified successfully');
        return true;
      } else {
        print(
          'Failed to modify reservation: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
}
