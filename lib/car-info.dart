import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'create-vehicle.dart';
import 'config.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';


// Model class for Vehicle that includes car model information
class Vehicle {
  String matricula;
  double carregaActual;
  double capacitatBateria;
  String model;
  String marca;
  int anyModel;
  List<String> tipusCarregador;
  int? propietari;
  int? id;

  Vehicle({
    required this.matricula,
    required this.carregaActual,
    required this.capacitatBateria,
    required this.model,
    required this.marca,
    required this.anyModel,
    required this.tipusCarregador,
    this.propietari,
    this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'matricula': matricula,
      'carrega_actual': carregaActual,
      'capacitat_bateria': capacitatBateria,
      'model_cotxe': 1, // Default value as per API requirements
      'propietari': propietari ?? 1, // Default value as per API requirements
      'model': model,
      'marca': marca,
      'any_model': anyModel,
      'tipus_carregador': tipusCarregador,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      matricula: json['matricula'],
      carregaActual: json['carrega_actual'] is int
          ? (json['carrega_actual'] as int).toDouble()
          : json['carrega_actual'],
      capacitatBateria: json['capacitat_bateria'] is int
          ? (json['capacitat_bateria'] as int).toDouble()
          : json['capacitat_bateria'],
      model: json['model'],
      marca: json['marca'],
      anyModel: json['any_model'],
      tipusCarregador: List<String>.from(json['tipus_carregador']),
      propietari: json['propietari'],
    );
  }
}

class CarInfo extends StatefulWidget {
  @override
  _CarInfoState createState() => _CarInfoState();
}

class _CarInfoState extends State<CarInfo> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Vehicle> _vehicles = [];

  static String token = '';
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();


  @override
  void initState() {
    super.initState();
    // Check for existing token when the login screen initializes
    _initialize();
  }

  Future<void> _initialize() async {
    token = (await getAccessToken())!;
    _fetchVehicles();
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  Future<void> _fetchVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse('${AppConfig.apiBase}/api_punts_carrega/vehicles/');
      print(url);
      final response = await http.get(url,
        headers: {'Authorization': 'Bearer ${token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print(data);
        setState(() {
          _vehicles = data.map((item) => Vehicle.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load vehicles: ${response.statusCode}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.car_info),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchVehicles,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateVehiclePage(
                onVehicleCreated: (vehicle) {
                  // Refresh the list after creating a new vehicle
                  _fetchVehicles();
                },
              ),
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Vehicle',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_errorMessage!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchVehicles,
              child: Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No vehicles found',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text('Tap the + button to add a new vehicle'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        return _buildVehicleCard(vehicle);
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${vehicle.marca} ${vehicle.model}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${vehicle.anyModel}',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('${context.loc.car_info_license_plate}: ${vehicle.matricula}'),
            SizedBox(height: 8),

            // Battery information
            Row(
              children: [
                Icon(Icons.battery_charging_full, size: 16),
                SizedBox(width: 4),
                Text('${vehicle.carregaActual} %'),
                SizedBox(width: 16),
                Icon(Icons.battery_full, size: 16),
                SizedBox(width: 4),
                Text('${vehicle.capacitatBateria} kWh'),
              ],
            ),
            SizedBox(height: 12),

            // Charger types
            Text('${context.loc.car_info_compatible_chargers}', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vehicle.tipusCarregador.map((charger) {
                return Chip(
                  label: Text(charger, style: TextStyle(fontSize: 12)),
                  backgroundColor: Colors.green.withOpacity(0.1),
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}