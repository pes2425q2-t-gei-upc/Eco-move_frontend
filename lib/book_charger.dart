import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:eco_move_frontend/routes/frontend_routes.dart';

import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class GoogleCalendarService {
  // Set up Google Sign-In with required scopes
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );

  // Function to save a booking to Google Calendar
  Future<bool> saveBookingToGoogleCalendar({
    required String title,
    required String startDate,
    required String startTime,
    required String duration,
    String? location,
    String? description,
  }) async {
    try {
      // Check if user is already signed in
      GoogleSignInAccount? googleUser = _googleSignIn.currentUser;

      // If not signed in, attempt to sign in
      if (googleUser == null) {
        googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          print('Google Sign-In was canceled by user');
          return false;
        }
      }

      // Get the authenticated client
      final auth = await googleUser.authentication;
      final httpClient = GoogleHttpClient(await googleUser.authHeaders);

      // Create a Calendar API client
      final calendarApi = calendar.CalendarApi(httpClient);

      // Parse the date (format: dd/mm/yyyy)
      final dateParts = startDate.split('/');
      if (dateParts.length != 3) {
        print('Invalid date format. Expected dd/mm/yyyy');
        return false;
      }

      final day = int.tryParse(dateParts[0]);
      final month = int.tryParse(dateParts[1]);
      final year = int.tryParse(dateParts[2]);

      if (day == null || month == null || year == null) {
        print('Invalid date values');
        return false;
      }

      // Parse the time (format: hh:mm)
      final timeParts = startTime.split(':');
      if (timeParts.length != 2) {
        print('Invalid time format. Expected hh:mm');
        return false;
      }

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);

      if (hour == null || minute == null) {
        print('Invalid time values');
        return false;
      }

      // Create start datetime in local timezone
      final startDateTime = DateTime(year, month, day, hour, minute);

      // Parse duration (format: hh:mm)
      final durationParts = duration.split(':');
      if (durationParts.length != 2) {
        print('Invalid duration format. Expected hh:mm');
        return false;
      }

      final durationHours = int.tryParse(durationParts[0]);
      final durationMinutes = int.tryParse(durationParts[1]);

      if (durationHours == null || durationMinutes == null) {
        print('Invalid duration values');
        return false;
      }

      // Calculate end datetime
      final endDateTime = startDateTime.add(
        Duration(hours: durationHours, minutes: durationMinutes),
      );

      // Create the calendar event with proper timezone handling
      final event = calendar.Event()
        ..summary = title
        ..start = (calendar.EventDateTime()
          ..dateTime = startDateTime
          ..timeZone = 'Europe/Madrid')
        ..end = (calendar.EventDateTime()
          ..dateTime = endDateTime
          ..timeZone = 'Europe/Madrid');

      // Add optional fields if provided
      if (location != null && location.isNotEmpty) {
        event.location = location;
      }

      if (description != null && description.isNotEmpty) {
        event.description = description;
      }

      // Insert the event to the user's primary calendar
      final createdEvent = await calendarApi.events.insert(event, 'primary');
      print('Event created successfully: ${createdEvent.htmlLink}');
      return true;

    } catch (e) {
      print('Error saving event to Google Calendar: $e');

      // Handle specific error cases
      if (e.toString().contains('insufficient authentication scopes')) {
        print('Insufficient permissions. User needs to re-authenticate.');
        await _googleSignIn.signOut();
      }

      return false;
    }
  }

  // Method to sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  // Method to check if user is signed in
  bool get isSignedIn => _googleSignIn.currentUser != null;
}

// Custom HTTP Client for Google APIs
class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}

class BookChargerScreen extends StatelessWidget {
  final String idStation;
  const BookChargerScreen({super.key, required this.idStation});

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
          child: DateTimePickerWithDropdown(idStation: idStation),
        ),
      ),
    );
  }
}

class DateTimePickerWithDropdown extends StatefulWidget {
  final String idStation;
  DateTimePickerWithDropdown({super.key, required this.idStation});
  @override
  _DateTimePickerWithDropdownState createState() =>
      _DateTimePickerWithDropdownState();
}

class _DateTimePickerWithDropdownState
    extends State<DateTimePickerWithDropdown> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  String? token = '';
  int myId = -1;
  bool _isCreatingReservation = false;

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
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
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
      initialTime: TimeOfDay.now(),
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
              maxLength: 5,
              buildCounter: (_, {required currentLength, required isFocused, required maxLength}) => null,
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
              onPressed: _isCreatingReservation ? null : () {
                if (_dateController.text.isNotEmpty &&
                    _timeController.text.isNotEmpty &&
                    _durationController.text.isNotEmpty &&
                    _isValidDuration(_durationController.text)) {
                  _showConfirmationDialog();
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
              child: _isCreatingReservation
                  ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : Text(
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

  void _showConfirmationDialog() {
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
              Text(
                context.loc.edit_booking_confirm_reservation,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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
                Navigator.of(context).pop();
                _processReservation();
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
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> showCalendarSaveDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Row(
            children: [
              Icon(Icons.calendar_today, size: 24),
              SizedBox(width: 8),
              Text(context.loc.save_calendar),
            ],
          ),
          content: Text(context.loc.save_calendar_quest),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child:  Text(context.loc.no),
            ),
            ElevatedButton(
              onPressed: () async {
                await _addToGoogleCalendar();
                Navigator.of(context).pop(true);
              },
              child:  Text(context.loc.yes),
            ),
          ],
        );
      },
    );
  }


  Future<void> _processReservation() async {
    // Validate date and time
    DateTime selectedDate = DateTime.parse(
      _dateController.text.isEmpty
          ? DateTime.now().toString()
          : _dateController.text
          .split('/')
          .reversed
          .join('-'),
    );

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
      _showErrorDialog(
        context.loc.reservation_invalid_datetime_title,
        context.loc.reservation_invalid_datetime_message,
      );
      return;
    }

    setState(() {
      _isCreatingReservation = true;
    });

    try {
      // Create reservation first
      bool reservationSuccess = await _createReservation(
        widget.idStation,
        _dateController.text,
        _timeController.text,
        _durationController.text,
      );

      if (reservationSuccess) {
        // Try to add to Google Calendar (optional)
        await showCalendarSaveDialog(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reservation created successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Navigate back
        Navigator.pop(context);
      } else {
        _showErrorDialog('Error', 'Failed to create reservation. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error', 'An unexpected error occurred: $e');
    } finally {
      setState(() {
        _isCreatingReservation = false;
      });
    }
  }

  Future<void> _addToGoogleCalendar() async {
    try {
      String? address = await _fetchStations(widget.idStation);
      final title = "${context.loc.booking_title}";
      final description = "${context.loc.booking_description}\n${context.loc.booking_station_address}${address ?? ''}\n${context.loc.booking_date}${_dateController.text}\n${context.loc.booking_time}${_timeController.text}\n${context.loc.booking_duration}${_durationController.text}";

      bool calendarSuccess = await _calendarService.saveBookingToGoogleCalendar(
        title: title,
        startDate: _dateController.text,
        startTime: _timeController.text,
        duration: _durationController.text,
        location: address,
        description: description,
      );

      if (calendarSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event added to Google Calendar'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Calendar integration failed (non-critical): $e');
      // Don't show error to user as this is optional
    }
  }

  void _showErrorDialog(String title, String message) {
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
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
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
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
    );
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  @override
  void initState() {
    super.initState();
    _initialize();

    _durationController.addListener(() {
      String text = _durationController.text.replaceAll(':', '').replaceAll('.', '');

      if (text.length > 4) text = text.substring(0, 4);

      String formatted = text;
      if (text.length > 2) {
        formatted = text.substring(0, 2) + ':' + text.substring(2);
      } else {
        formatted = text;
      }

      _durationController.value = _durationController.value.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }

  Future<void> _initialize() async {
    token = await getAccessToken();
    print('Token: $token');
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
    return null;
  }

  Future<bool> _createReservation(
      String id,
      String date,
      String hour,
      String duration,
      ) async {
    final url = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.reservasCrear),
    );

    final Map<String, dynamic> data = {
      'estacion': id,
      'fecha': date,
      'hora': hour,
      'duracion': duration,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        print('Reservation created successfully');
        await addPoints();
        return true;
      } else {
        print('Failed to create reservation: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error creating reservation: $e');
      return false;
    }
  }

  Future<void> _getInfo() async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.me));

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        myId = data['id'];
        print('User data: $data');
      } else {
        print('Failed to load user info: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting user info: $e');
    }
  }

  Future<void> addPoints() async {
    await _getInfo();

    final url = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.addPoints(myId)),
    );

    final Map<String, dynamic> data = {
      'punts': 10,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        print('Points added successfully');
      } else {
        print('Failed to add points: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error adding points: $e');
    }
  }
}