import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:eco_move_frontend/routes/frontend_routes.dart';

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
                          child: Text(conext.loc.common_cancel),
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
                              createReservation(
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

  Future<void> createReservation(
    String id,
    String date,
    String hour,
    String? duration,
  ) async {
    final url = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.createReservation),
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
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        print('Reservation created successfully');
      } else {
        print(
          'Failed to create reservation: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
