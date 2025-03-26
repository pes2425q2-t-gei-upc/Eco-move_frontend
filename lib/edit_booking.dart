import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EditChargerScreen(date: '', hour: '', duration: '',),
    );
  }
}


class EditChargerScreen extends StatelessWidget {

  final String date;
  final String hour;
  final String duration;

  const EditChargerScreen({super.key, required this.date, required this.hour, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Editar reserva del cargador',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(30.0),
        child: DateTimePickerWithDropdown(
          date: date,
          hour: hour,
          duration: duration
        ),
      ),
    );
  }
}

class DateTimePickerWithDropdown extends StatefulWidget {

  final String date;
  final String hour;
  final String duration;

  const DateTimePickerWithDropdown({
    super.key,
    required this.date,
    required this.hour,
    required this.duration,
  });


  @override
  _DateTimePickerWithDropdownState createState() =>
      _DateTimePickerWithDropdownState();
}

class _DateTimePickerWithDropdownState
    extends State<DateTimePickerWithDropdown> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();


  DateTime? _initialDate;
  TimeOfDay? _initialTime;
  String? _selectedValue;

  void initState() {
    super.initState();

    // Set initial values from widget parameters
    _dateController.text = widget.date;
    _timeController.text = widget.hour;
    _selectedValue = widget.duration;
    print(widget.duration);

    // Parse the date and time
    _initialDate = DateTime.tryParse(widget.date);  // Assuming the date format is "yyyy-MM-dd"
    _initialTime = TimeOfDay(
      hour: int.parse(widget.hour.split(":")[0]),
      minute: int.parse(widget.hour.split(":")[1]),
    );
  }

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
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Confirmar modificación'),
                        content: Text(
                            '¿Estás seguro de que deseas modificar la reserva?\n\nFecha: ${_dateController.text}\nHora: ${_timeController.text}\nDuración: $_selectedValue'),
                      actions: <Widget>[
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancelar')
                        ),
                        TextButton(
                            onPressed: () {
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
}
