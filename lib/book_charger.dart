import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'dart:convert';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BookChargerScreen(),
    );
  }
}


class BookChargerScreen extends StatelessWidget {
  const BookChargerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reservar cargador',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(30.0),
        child: DateTimePickerWithDropdown(),
      ),
    );
  }
}

class DateTimePickerWithDropdown extends StatefulWidget {
  @override
  _DateTimePickerWithDropdownState createState() =>
      _DateTimePickerWithDropdownState();
}

class _DateTimePickerWithDropdownState
    extends State<DateTimePickerWithDropdown> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final MaskedTextController _durationController = MaskedTextController(mask: '00:00');


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
        SizedBox(height: 16), // Space between fields

        // Time Picker Field
        Text('Hora'),
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
            decoration: InputDecoration(labelText: 'Duración estimada (hh:mm)'),
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
                    builder: (BuildContext conext)
                {
                  return AlertDialog(
                    title: Text('Confirmar reserva'),
                    content: Text(
                        '¿Estás seguro de que deseas reservar?\n\nFecha: ${_dateController
                            .text}\nHora: ${_timeController
                            .text}\nDuración: ${_durationController.text}'),
                    actions: <Widget>[
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Cancelar')
                      ),
                      TextButton(
                          onPressed: () {
                            createReservation('46391170', _dateController.text,
                                _timeController.text, _durationController.text);
                            Navigator.of(context).pop(); // Close the dialog
                            Navigator.pop(
                                context); // Go back to the previous screen
                          },
                          child: Text('Confirmar')
                      ),
                    ],
                  );
                }
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Por favor, selecciona fecha, hora y duración estimada'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Color(0xffa610ad),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Confirmar reserva'),
          ),
        ),
      ],
    );
  }

  Future<void> createReservation(String id, String date, String hour, String? duration) async {
    final url = Uri.parse('http://10.0.2.2:8000/api_punts_carrega/reservas/crear/');

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
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        print('Reservation created successfully');
      } else {
        print('Failed to create reservation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  

}
