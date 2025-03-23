import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:http/http.dart' as http;


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EditChargerScreen(date: '', hour: '', duration: '', id: 0 ,estacion: '',),
    );
  }
}


class EditChargerScreen extends StatelessWidget {

  final String date;
  final String hour;
  final String duration;
  final int id;
  final String estacion;

  const EditChargerScreen({super.key, required this.date, required this.hour, required this.duration, required this.id, required this.estacion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Editar reserva del cargador $estacion',
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
  final MaskedTextController _durationController = MaskedTextController(mask: '00:00:00');



  DateTime? _initialDate;
  TimeOfDay? _initialTime;


  void initState() {
    super.initState();

    // Set initial values from widget parameters
    _dateController.text = widget.date;
    _timeController.text = widget.hour;
    _durationController.text = widget.duration;
    print(widget.duration);

    // Parse the date and time
    _initialDate = DateTime.tryParse(widget.date);  // Assuming the date format is "yyyy-MM-dd"
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

  // Function to show the date picker
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _initialDate,
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
            hintText: 'HH:mm',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.access_time),
          ),
          readOnly: true,
          onTap: _selectTime,
        ),
        SizedBox(height: 16), // Space between fields

        TextField(
          controller: _durationController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Duración estimada (hh:mm:ss)'),
        ),
        SizedBox(height: 30),

        // Button to confirm the date, time, and dropdown selection
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
                        title: Text('Confirmar modificación'),
                        content: Text(
                            '¿Estás seguro de que deseas modificar la reserva?\n\nFecha: ${_dateController.text}\nHora: ${_timeController.text}\nDuración: ${_durationController.text}'),
                      actions: <Widget>[
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancelar')
                        ),
                        TextButton(
                            onPressed: () {
                              editBooking(widget.id, _dateController.text, _timeController.text, _durationController.text, widget.estacion);
                              Navigator.of(context).pop(); // Close the dialog
                              Navigator.pop(context); // Go back to the previous screen
                            },
                            child: Text('Confirmar')
                        ),
                      ],
                      );
                    },
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
            child: Text('Confirmar modificación'),
          ),
        ),
      ],
    );
  }

  Future<void> editBooking(int id, String date, String hour, String? duration, String estacion) async {
    final url = Uri.parse('http://10.0.2.2:8000/api_punts_carrega/reservas/$id/modificar/');

    final Map<String, dynamic> data = {
      'estacion': estacion,
      'fecha': date,
      'hora': hour,
      'duracion': duration,
    };

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        print('Reservation created successfully');
      } else {
        print('Failed to create reservation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }


}
