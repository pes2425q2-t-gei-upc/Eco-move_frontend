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
      // Authenticate with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In was canceled');
        return false;
      }

      // Get the authenticated client
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        print('Failed to get authenticated client');
        return false;
      }

      // Create a Calendar API client
      final calendarApi = calendar.CalendarApi(httpClient);

      // Parse the date (format: dd/mm/yyyy)
      final dateParts = startDate.split('/');
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);

      // Parse the time (format: hh:mm)
      final timeParts = startTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Create start datetime
      final startDateTime = DateTime(year, month, day, hour, minute);

      // Parse duration (format: hh:mm)
      final durationParts = duration.split(':');
      final durationHours = int.parse(durationParts[0]);
      final durationMinutes = int.parse(durationParts[1]);

      // Calculate end datetime
      final endDateTime = startDateTime.add(
        Duration(hours: durationHours, minutes: durationMinutes),
      );

      // Create the calendar event
      final start = calendar.EventDateTime()
        ..dateTime = startDateTime.toUtc()
        ..timeZone = 'Europe/Madrid'; // or another valid IANA time zone

      final end = calendar.EventDateTime()
        ..dateTime = endDateTime.toUtc()
        ..timeZone = 'Europe/Madrid';

      final event = calendar.Event()
        ..summary = title
        ..start = start
        ..end = end;

      // Add optional fields if provided
      if (location != null && location.isNotEmpty) {
        event.location = location;
      }

      if (description != null && description.isNotEmpty) {
        event.description = description;
      }

      // Insert the event to the user's primary calendar
      final createdEvent = await calendarApi.events.insert(event, 'primary');
      print('Event created: ${createdEvent.htmlLink}');
      return true;
    } catch (e) {
      print('Error saving event to Google Calendar: $e');
      return false;
    }
  }
}

// Extension for the existing _DateTimePickerWithDropdownState class
extension GoogleCalendarExtension on _DateTimePickerWithDropdownState {
  // Function to save booking to Google Calendar
  Future<void> saveBookingToGoogleCalendar(String stationId, String date, String time, String duration) async {
    final GoogleCalendarService calendarService = GoogleCalendarService();

    // Create a meaningful title and description for the event
    final title = "${context.loc.booking_title}";
    final description = "${context.loc.booking_description}\n${context.loc.booking_station_address}$stationId\n${context.loc.booking_date}$date\n${context.loc.booking_time}$time\n${context.loc.booking_duration}$duration";

    // Try to get station location info (if available in your app)
    String? location;
    // If you have a way to get station address/location, add it here
    // location = await getStationLocation(stationId);

    final success = await calendarService.saveBookingToGoogleCalendar(
      title: title,
      startDate: date,
      startTime: time,
      duration: duration,
      location: location,
      description: description,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guardat')),
      );
    } else {
      // Only show error if user didn't cancel the sign-in process
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error')),
      );
    }
  }
}





class BookChargerScreen extends StatelessWidget {
  final String idStation;
  const BookChargerScreen({super.key, required this.idStation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.loc.reservations_book_charger,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(30.0),
        child: DateTimePickerWithDropdown(idStation: idStation),
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
  final MaskedTextController _durationController = MaskedTextController(
    mask: '00:00',
  );

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  String? token = '';
  int myId = -1;

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // Function to show the date picker
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Picker Field
        Text(context.loc.common_date),
        SizedBox(height: 8),
        TextField(
          controller: _dateController,
          decoration: InputDecoration(
            hintText: 'dd/mm/yyyy',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today),
          ),
          readOnly: true,
          onTap: _selectDate,
        ),
        SizedBox(height: 16), // Space between fields
        // Time Picker Field
        Text(context.loc.common_hour),
        SizedBox(height: 8),
        TextField(
          controller: _timeController,
          decoration: InputDecoration(
            hintText: 'hh:mm',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.access_time),
          ),
          readOnly: true,
          onTap: _selectTime,
        ),
        SizedBox(height: 16), // Space between fields
        // Dropdown Menu
        TextField(
          controller: _durationController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '${context.loc.reservations_duration_hint} (hh:mm)',
          ),
        ),
        SizedBox(height: 8),

        // Button to confirm the date, time, and dropdown selection
        Center(
          child: TextButton(
            onPressed: () {
              if (_dateController.text.isNotEmpty &&
                  _timeController.text.isNotEmpty &&
                  _durationController.text.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (BuildContext conext) {
                    return AlertDialog(
                      title: Text(conext.loc.edit_booking_confirm_reservation),
                      content: Text(
                        '${conext.loc.reservation_confirm_question}\n\n${conext.loc.common_date}: ${_dateController.text}\n${conext.loc.common_hour}: ${_timeController.text}\n${conext.loc.common_duration}: ${_durationController.text}',
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(context.loc.common_cancel),
                        ),
                        TextButton(
                          onPressed: () {
                            // Parse the selected date
                            DateTime selectedDate = DateTime.parse(
                              _dateController.text.isEmpty
                                  ? DateTime.now().toString()
                                  : _dateController.text
                                      .split('/')
                                      .reversed
                                      .join('-'), // Convert to DateTime
                            );

                            // Parse the selected time
                            List<String> timeParts = _timeController.text.split(
                              ':',
                            );
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
                              // Show the dialog if the selected date and time are invalid
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      context
                                          .loc
                                          .reservation_invalid_datetime_title,
                                    ),
                                    content: Text(
                                      context
                                          .loc
                                          .reservation_invalid_datetime_message,
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(context.loc.common_close),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              // Proceed with reservation creation if valid
                              createReservationWithCalendar(
                                context,
                                widget.idStation,
                                _dateController.text,
                                _timeController.text,
                                _durationController.text,
                              );

                              Navigator.of(context).pop(); // Close the dialog
                              Navigator.pop(
                                context,
                              ); // Go back to the previous screen
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Color(0xffa610ad),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            conext.loc.edit_booking_confirm_reservation,
                          ),
                        ),
                      ],
                    );
                  },
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.loc.edit_booking_missing_field),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Color(0xffa610ad),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(context.loc.edit_booking_confirm_reservation),
          ),
        ),
      ],
    );
  }

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
    print('Token: $token');
  }

  Future<String?> _fetchStations(String idStation) async {
    final url = Uri.parse(
      FrontendRoutes.build(
        FrontendRoutes.estacion(idStation),
      ), // Ensure this URL is correct
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        Map<String, dynamic> data = jsonDecode(decodedResponse);
        return data['direccio'];

      } else {
        print(
          'Error: Received status code ${response.statusCode}',
        ); // Print error if status code isn't 200
      }
    } catch (e) {
      print(
        'Error during HTTP request: $e',
      ); // Catch any errors during the request
    }

    return '';
  }

  Future<void> createReservationWithCalendar(
      BuildContext context,
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

        // Then, save to Google Calendar
        final GoogleCalendarService calendarService = GoogleCalendarService();


        String? address = await _fetchStations(id);


        final title = "${context.loc.booking_title}";
        final description = "${context.loc.booking_description}\n${context.loc.booking_station_address}$address\n${context.loc.booking_date}$date\n${context.loc.booking_time}$hour\n${context.loc.booking_duration}$duration";


        await calendarService.saveBookingToGoogleCalendar(
          title: title,
          startDate: date,
          startTime: hour,
          duration: duration,
          description: description,
        );

        addPoints();
      } else {
        print(
          'Failed to create reservation: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error: $e');
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
        print('Les dades són: $data');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user info')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> addPoints() async {
    await _getInfo();

    final urlMe = Uri.parse(FrontendRoutes.build(FrontendRoutes.me));

    final url = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.addPoints(myId)),
    );

    final Map<String, dynamic> data = {
      'punts': 100,
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

      if (response.statusCode == 20) {
        print('Se han sumado bien los puntos');

      } else {
        print(
          'Failed to create reservation: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating reservation: $e')),
      );
    }
  }
}
