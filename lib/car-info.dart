import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(CarInfoApp());
}

class CarInfoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Info App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Keep track of created models
  List<CarModel> carModels = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Car Information'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to Car Info App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateModelPage(
                      onModelCreated: (model) {
                        setState(() {
                          carModels.add(model);
                        });
                      },
                    ),
                  ),
                );
              },
              child: Text('Create Car Model'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: carModels.isEmpty
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateVehiclePage(
                      availableModels: carModels,
                    ),
                  ),
                );
              },
              child: Text('Create Vehicle'),
            ),
            SizedBox(height: 20),
            if (carModels.isNotEmpty) ...[
              Text(
                'Your Car Models:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: carModels.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: ListTile(
                        title: Text(carModels[index].model),
                        subtitle: Text('Brand: ${carModels[index].marca}, Year: ${carModels[index].anyModel}'),
                        trailing: Text('Chargers: ${carModels[index].tipusCarregador.length}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Model classes
class CarModel {
  String model;
  String marca;
  int anyModel;
  List<String> tipusCarregador;

  CarModel({
    required this.model,
    required this.marca,
    required this.anyModel,
    required this.tipusCarregador,
  });

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'marca': marca,
      'any_model': anyModel,
      'tipus_carregador': tipusCarregador,
    };
  }
}

class Vehicle {
  String matricula;
  double carregaActual;
  double capacitatBateria;
  CarModel modelCotxe;
  String? propietari;

  Vehicle({
    required this.matricula,
    required this.carregaActual,
    required this.capacitatBateria,
    required this.modelCotxe,
    this.propietari,
  });

  Map<String, dynamic> toJson() {
    return {
      'matricula': matricula,
      'carrega_actual': carregaActual,
      'capacitat_bateria': capacitatBateria,
      'model_cotxe': modelCotxe.toJson(),
      'propietari': propietari,
    };
  }
}

// Create Model Page
class CreateModelPage extends StatefulWidget {
  final Function(CarModel) onModelCreated;

  CreateModelPage({required this.onModelCreated});

  @override
  _CreateModelPageState createState() => _CreateModelPageState();
}

class _CreateModelPageState extends State<CreateModelPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  List<String> _availableChargers = [
    'Mennekes.M AC',
    'Schuko AC',
    'Ccs Combo2 AC/DC',
    'Chademo AC/DC',
    'Mennekes.M AC/DC',
    'Ccs Combo2 DC',
    'Schuko AC/DC',
    'Chademo DC',
    'Mennekes.M DC'
  ];

  List<String> _selectedChargers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Car Model'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _modelController,
                decoration: InputDecoration(
                  labelText: 'Model Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter model name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _marcaController,
                decoration: InputDecoration(
                  labelText: 'Brand (Marca)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter brand name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                decoration: InputDecoration(
                  labelText: 'Year (Any Model)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter year';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid year';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              Text(
                'Select Charger Types:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('Select charger types'),
                    items: _availableChargers.map((String charger) {
                      return DropdownMenuItem<String>(
                        value: charger,
                        child: Text(charger),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null && !_selectedChargers.contains(newValue)) {
                        setState(() {
                          _selectedChargers.add(newValue);
                        });
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
              if (_selectedChargers.isNotEmpty) ...[
                Text(
                  'Selected Chargers:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedChargers.map((charger) {
                    return Chip(
                      label: Text(charger),
                      deleteIcon: Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedChargers.remove(charger);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              SizedBox(height: 24),
              if (_selectedChargers.isEmpty)
                Text(
                  'Please select at least one charger type',
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && _selectedChargers.isNotEmpty) {
                    // Create and save the model
                    final carModel = CarModel(
                      model: _modelController.text,
                      marca: _marcaController.text,
                      anyModel: int.parse(_yearController.text),
                      tipusCarregador: _selectedChargers,
                    );

                    widget.onModelCreated(carModel);

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Car model created successfully')),
                    );

                    // Go back to home page
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  child: Center(
                    child: Text(
                      'Create Model',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Create Vehicle Page
class CreateVehiclePage extends StatefulWidget {
  final List<CarModel> availableModels;

  CreateVehiclePage({required this.availableModels});

  @override
  _CreateVehiclePageState createState() => _CreateVehiclePageState();
}

class _CreateVehiclePageState extends State<CreateVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _carregaController = TextEditingController();
  final TextEditingController _capacitatController = TextEditingController();

  CarModel? _selectedModel;
  String? _userId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://nattech.fib.upc.edu:40502/me/'),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          _userId = userData['id'].toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load user info: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error connecting to server: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate() && _selectedModel != null) {
      final vehicle = Vehicle(
        matricula: _matriculaController.text,
        carregaActual: double.parse(_carregaController.text),
        capacitatBateria: double.parse(_capacitatController.text),
        modelCotxe: _selectedModel!,
        propietari: _userId,
      );

      // Here you would typically send this data to your backend
      // For now, we'll just show a success message

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehicle saved successfully')),
      );

      // Print the JSON for debugging
      print(jsonEncode(vehicle.toJson()));

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Create Vehicle')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Create Vehicle')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchUserInfo,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Vehicle'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _matriculaController,
                decoration: InputDecoration(
                  labelText: 'Plate Number (Matrícula)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter plate number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _carregaController,
                decoration: InputDecoration(
                  labelText: 'Current Charge (kWh)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter current charge';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _capacitatController,
                decoration: InputDecoration(
                  labelText: 'Battery Capacity (kWh)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter battery capacity';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              Text(
                'Select Car Model:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CarModel>(
                    isExpanded: true,
                    hint: Text('Select a car model'),
                    value: _selectedModel,
                    items: widget.availableModels.map((CarModel model) {
                      return DropdownMenuItem<CarModel>(
                        value: model,
                        child: Text('${model.marca} ${model.model} (${model.anyModel})'),
                      );
                    }).toList(),
                    onChanged: (CarModel? newValue) {
                      setState(() {
                        _selectedModel = newValue;
                      });
                    },
                  ),
                ),
              ),
              if (_selectedModel != null) ...[
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Model Details:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('Model: ${_selectedModel!.model}'),
                        Text('Brand: ${_selectedModel!.marca}'),
                        Text('Year: ${_selectedModel!.anyModel}'),
                        Text('Chargers: ${_selectedModel!.tipusCarregador.join(", ")}'),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 24),
              Text(
                'Owner ID: $_userId',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _selectedModel == null ? null : _saveVehicle,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  child: Center(
                    child: Text(
                      'Save Vehicle',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}