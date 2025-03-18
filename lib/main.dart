import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECO-MOVE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MyHomePage(title: 'ECO-MOVE'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> estaciones = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchEstaciones() async {
    final url = Uri.parse(
      'https://eco-move-backend.onrender.com/api_punts_carrega/ubicacions/',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
          json.decode(response.body),
        );
        setState(() {
          estaciones = data;
        });
      } else {
        print('Error al cargar datos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la solicitud: $e');
    }
  }

  void _showAlert() {
    TextEditingController mensajeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enviar alerta"),
          content: TextField(
            controller: mensajeController,
            decoration: const InputDecoration(
              hintText: "Mensaje opcional",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Enviar"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEstacionesList() {
    return ListView(
      padding: const EdgeInsets.all(10),
      children:
          estaciones.map((estacion) => _buildEstacionCard(estacion)).toList(),
    );
  }

  Widget _buildEstacionCard(Map<String, dynamic> estacion) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID Ubicación: ${estacion['id_ubicacio']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Dirección: ${estacion['direccio']}'),
            Text('Ciudad: ${estacion['ciutat']}'),
            Text('Provincia: ${estacion['provincia']}'),
            Text('Latitud: ${estacion['lat']}'),
            Text('Longitud: ${estacion['lng']}'),
          ],
        ),
      ),
    );
  }

  Widget _showMap() {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(41.38974691281002, 2.1133222801818614),
        minZoom: 10.0,
        maxZoom: 25.0,
        zoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_selectedIndex == 2) {
        _fetchEstaciones();
      } else if (_selectedIndex == 1) {
        _showMap();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body:
          _selectedIndex == 2
              ? _buildEstacionesList()
              : (_selectedIndex == 1 ? _showMap() : Container()),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CircleAvatar(
            backgroundColor: Colors.red,
            radius: 22,
            child: IconButton(
              icon: const Icon(Icons.warning, color: Colors.white),
              onPressed: () {
                _showAlert();
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.ev_station),
            label: 'Estaciones',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: _onItemTapped,
      ),
    );
  }
}
