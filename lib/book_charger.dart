import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


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

  String? _selectedValue;
  final List<String> _dropdownItems = [
    '30 minutos',
    '1 hora',
    '1 hora 30 minutos',
    '2 horas'
  ];

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

  List<Map<String, dynamic>> estaciones = [];
//MIRAR COM FER EL POST
  Future<void> _fetchEstacion(Map<String, dynamic> nuevaEstacion) async {
    final url = Uri.parse(
      'https://eco-move-backend.onrender.com/api_punts_carrega/ubicacions/',
    );
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(nuevaEstacion),
      );

      if (response.statusCode == 201) {
        print('Estación creada correctamente');
        // Si necesitas actualizar la lista después de crearla:
        _fetchEstaciones();
      } else {
        print('Error al crear estación: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error en la solicitud: $e');
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

        // Dropdown Menu
        Text('Duración estimada'),
        SizedBox(height: 8),
        DropdownButton<String>(
          value: _selectedValue,
          hint: Text('-'),
          onChanged: (String? newValue) {
            setState(() {
              _selectedValue = newValue;
            });
          },
          items: _dropdownItems.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
        SizedBox(height: 30),

        // Button to confirm the date, time, and dropdown selection
        Center(
          child: TextButton(
            onPressed: () {
              if (_dateController.text.isNotEmpty &&
                  _timeController.text.isNotEmpty &&
                  _selectedValue != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Fecha: ${_dateController.text} - Hora: ${_timeController.text} - Opción: $_selectedValue'),

                  ),
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
}
