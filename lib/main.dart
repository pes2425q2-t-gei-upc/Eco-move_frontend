import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'gestio_reserva.dart';
import 'package:geolocator/geolocator.dart';

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
  LatLng? myPosition;
  String filtroSeleccionado = 'Todas';

  @override
  void initState() {
    super.initState();
    _getPosition();
    _fetchEstaciones();
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    permission = await Geolocator.checkPermission();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions denied');
      }
    }
    return await Geolocator.getCurrentPosition();
  }

  void _getPosition() async {
    Position? position = await _determinePosition();
    if (position != null) {
      setState(() {
        myPosition = LatLng(position.latitude, position.longitude);
      });
    }
  }

  Future<void> _fetchEstaciones() async {
    String endpoint;

    if (filtroSeleccionado == 'Todas') {
      endpoint =
          'https://eco-move-backend.onrender.com/api_punts_carrega/estacions/';
    } else {
      if (myPosition != null) {
        endpoint =
            'https://eco-move-backend.onrender.com/api_punts_carrega/punt_mes_proper/?lat=${myPosition!.latitude}&lng=${myPosition!.longitude}';
      } else {
        print('Error: myPosition es null');
        return;
      }
    }

    final url = Uri.parse(endpoint);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        List<Map<String, dynamic>> filteredData =
            data.map((estacion) {
              // Si la respuesta es de "Más cercanas", accedemos a "estacio_carrega"
              Map<String, dynamic> estacioCarrega =
                  estacion.containsKey('estacio_carrega')
                      ? estacion['estacio_carrega']
                      : estacion;

              return {
                "id_punt": estacioCarrega["id_punt"],
                "lat": estacioCarrega["lat"],
                "lng": estacioCarrega["lng"],
                "direccio": estacioCarrega["direccio"],
                "ciutat": estacioCarrega["ciutat"],
                "nplaces_lliures": estacioCarrega["nplaces"],
                "potencia": estacioCarrega["potencia"],
                "tipus_velocitat": estacioCarrega["tipus_velocitat"],
              };
            }).toList();

        setState(() {
          estaciones = filteredData;
        });
      } else {
        print('Error al cargar datos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la solicitud: $e');
    }
  }

  void _abrirEstacionScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => EstacionScreen()));
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: DropdownButton<String>(
            value: filtroSeleccionado,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  filtroSeleccionado = newValue;
                  _fetchEstaciones();
                });
              }
            },
            items:
                ['Todas', 'Más cercanas'].map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(10),
            children:
                estaciones
                    .map((estacion) => _buildEstacionCard(estacion))
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEstacionCard(Map<String, dynamic> estacion) {
    return InkWell(
      onTap: () {
        _abrirEstacionScreen(context);
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ID Punto: ${estacion['id_punt']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Dirección: ${estacion['direccio']}'),
              Text('Ciudad: ${estacion['ciutat']}'),
              Text('Plazas libres: ${estacion['nplaces_lliures']}'),
              Text('Potencia: ${estacion['potencia']} kW'),
              Text('Tipo de velocidad: ${estacion['tipus_velocitat']}'),
            ],
          ),
        ),
      ),
    );
  }

  MarkerLayer _buildMarkersLayer() {
    return MarkerLayer(
      markers:
          estaciones.map((estacion) {
            return Marker(
              width: 40.0,
              height: 40.0,
              point: LatLng(estacion['lat'], estacion['lng']),
              builder:
                  (ctx) => Container(
                    child: IconButton(
                      icon: Icon(Icons.location_on),
                      color: Colors.red,
                      iconSize: 30,
                      onPressed: () {
                        _abrirEstacionScreen(context);
                      },
                    ),
                  ),
            );
          }).toList(),
    );
  }

  Widget _showMap() {
    return FlutterMap(
      options: MapOptions(
        center: myPosition,
        minZoom: 5.0,
        maxZoom: 25.0,
        zoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        _buildMarkersLayer(),
        if (myPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                width: 40.0,
                height: 40.0,
                point: myPosition!,
                builder:
                    (ctx) =>
                        Icon(Icons.location_pin, color: Colors.blue, size: 30),
              ),
            ],
          ),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_selectedIndex == 2) {
      } else if (_selectedIndex == 1) {
        _getPosition();
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
