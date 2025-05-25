import 'dart:io';

import 'package:eco_move_frontend/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'car-info.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';


class CreateVehiclePage extends StatefulWidget {
  final Function(Vehicle) onVehicleCreated;

  CreateVehiclePage({required this.onVehicleCreated});

  @override
  _CreateVehiclePageState createState() => _CreateVehiclePageState();
}

class _CreateVehiclePageState extends State<CreateVehiclePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _carregaController = TextEditingController();
  final TextEditingController _capacitatController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  int? _userId;
  bool _isLoading = false;
  String? _errorMessage;

  List<String> _availableChargers = [
    'Mennekes.M AC', 'Schuko AC', 'Ccs Combo2 AC/DC', 'Chademo AC/DC',
    'Mennekes.M AC/DC', 'Ccs Combo2 DC', 'Schuko AC/DC', 'Chademo DC', 'Mennekes.M DC'
  ];

  List<String> _selectedChargers = [];

  static String token = '';
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();


  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    token = (await getAccessToken())!;
   // fetchUserInfo();
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }
  

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate() && _selectedChargers.isNotEmpty) {
      // Create vehicle with embedded car model information
      final vehicle = Vehicle(
        matricula: _matriculaController.text,
        carregaActual: double.parse(_carregaController.text),
        capacitatBateria: double.parse(_capacitatController.text),
        model: _modelController.text,
        marca: _marcaController.text,
        anyModel: int.parse(_yearController.text),
        tipusCarregador: _selectedChargers,
        propietari: _userId,
      );

      try {
        await createVehicle(vehicle);

        // Notify parent widget
        widget.onVehicleCreated(vehicle);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle saved successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving vehicle: $e')),
        );
      }
    } else if (_selectedChargers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one charger type')),
      );
    }
  }

  Future<void> createVehicle(Vehicle vehicle) async {
    final url = Uri.parse('${AppConfig.apiBase}/api_punts_carrega/vehicles/');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'},
      body: jsonEncode(vehicle.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create vehicle: ${response.statusCode} - ${response.body}');
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
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
              Icon(Icons.error_outline, size: 40, color: Colors.red),
              SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              SizedBox(height: 16),
              /*ElevatedButton(
                onPressed: fetchUserInfo,
                child: Text('Retry'),
              ), */
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.loc.car_info_create)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Information
              Text(context.loc.car_info_vehicle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),

              _buildInputField(
                controller: _matriculaController,
                label: context.loc.car_info_license_plate,
                icon: Icons.credit_card,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter plate number' : null,
              ),
              SizedBox(height: 16),

              _buildInputField(
                controller: _carregaController,
                label: '${context.loc.car_info_actual_capacity} (%)',
                icon: Icons.battery_charging_full,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter current charge';
                  if (double.tryParse(value!) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              SizedBox(height: 16),

              _buildInputField(
                controller: _capacitatController,
                label: '${context.loc.car_info_battery_capacity} (kWh)',
                icon: Icons.battery_full,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter battery capacity';
                  if (double.tryParse(value!) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Car Model Information
              Text(context.loc.car_info_model_info, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),

              _buildInputField(
                controller: _modelController,
                label: context.loc.car_info_model,
                icon: Icons.branding_watermark,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter model name' : null,
              ),
              SizedBox(height: 16),

              _buildInputField(
                controller: _marcaController,
                label: context.loc.car_info_brand,
                icon: Icons.business,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter brand name' : null,
              ),
              SizedBox(height: 16),

              _buildInputField(
                controller: _yearController,
                label: context.loc.car_info_year,
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter year';
                  if (int.tryParse(value!) == null) return 'Please enter a valid year';
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Compatible Chargers
              Text(context.loc.car_info_compatible_chargers, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),

              // Dropdown for charger selection
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: context.loc.car_info_select_charger,
                  prefixIcon: Icon(Icons.electrical_services),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(Icons.arrow_drop_down),
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
              SizedBox(height: 16),

              // Selected chargers chips
              if (_selectedChargers.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedChargers.map((charger) {
                    return Chip(
                      label: Text(charger),
                      deleteIcon: Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedChargers.remove(charger);
                        });
                      },
                    );
                  }).toList(),
                ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveVehicle,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(context.loc.car_info_save, style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}