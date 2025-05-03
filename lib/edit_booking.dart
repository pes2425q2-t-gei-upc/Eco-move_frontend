import 'dart:convert';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
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
      appBar: AppBar(
        title: Text(
          '${context.loc.edit_booking_title} $estacion',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(30.0),
        child: DateTimePickerWithDropdown(
          id: id,
          date: date,
          hour: hour,
          duration: duration,
          estacion: estacion,
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

  @override
  void initState() {
    super.initState();

    _dateController.text = widget.date;
    _timeController.text = widget.hour;
    _durationController.text = widget.duration;

    _initialDate = DateTime.tryParse(widget.date);
    _initialTime = TimeOfDay(
      hour: int.parse(widget.hour.split(":")[0]),
      minute: int.parse(widget.hour.split(":")[1]),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _initialDate ?? DateTime.now(),
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

  Future<void> _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _initialTime ?? TimeOfDay.now(),
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
        Text('Fecha'),
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
        SizedBox(height: 16),

        Text(context.loc.common_hour),
        SizedBox(height: 8),
        TextField(
          controller: _timeController,
          decoration: InputDecoration(
            hintText: 'HH:mm',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.access_time),
          ),
          readOnly: true,
          onTap: _selectTime,
        ),
        SizedBox(height: 16),

        TextField(
          controller: _durationController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Duración estimada (hh:mm)'),
        ),
        SizedBox(height: 30),

        Center(
          child: TextButton(
            onPressed: () {
              if (_dateController.text.isNotEmpty &&
                  _timeController.text.isNotEmpty &&
                  _durationController.text.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(context.loc.edit_booking_confirm_title),
                      content: Text(
                        '${context.loc.edit_booking_confirm_question}\n\n${context.loc.common_date}: ${_dateController.text}\n${context.loc.common_hour}: ${_timeController.text}\n${context.loc.common_duration}: ${_durationController.text}',
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(context.loc.common_cancel),
                        ),
                        TextButton(
                          onPressed: () async {
                            String selectedDate = _dateController.text;

                            List<String> dateParts = selectedDate.split('/');
                            int day = int.parse(dateParts[0]);
                            int month = int.parse(dateParts[1]);
                            int year = int.parse(dateParts[2]);

                            List<String> timeParts = _timeController.text.split(
                              ':',
                            );
                            int hour = int.parse(timeParts[0]);
                            int minute = int.parse(timeParts[1]);

                            DateTime selectedDateTime = DateTime(
                              year,
                              month,
                              day,
                              hour,
                              minute,
                            );

                            if (selectedDateTime.isBefore(DateTime.now())) {
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
                                          .edit_booking_invalid_datetime_message,
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
                              bool success = await editBooking(
                                widget.id,
                                selectedDate,
                                _timeController.text,
                                _durationController.text,
                                widget.estacion,
                              );

                              if (success) {
                                Navigator.of(context).pop();
                                Navigator.pop(context, true);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.loc.edit_booking_error,
                                    ),
                                  ),
                                );
                                Navigator.of(context).pop();
                              }
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
                            context.loc.edit_booking_confirm_reservation,
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
            child: Text(context.loc.edit_booking_confirm_title),
          ),
        ),
      ],
    );
  }

  Future<bool> editBooking(
    int id,
    String date,
    String hour,
    String? duration,
    String estacion,
  ) async {
    final url = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.editReservation(id)),
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
        headers: {'Content-Type': 'application/json'},
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
