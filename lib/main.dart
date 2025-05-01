import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'gestio_reserva.dart';
import 'package:geolocator/geolocator.dart';
import 'get_bookings.dart';
import 'log_in.dart';
import 'refugio_screen.dart';
import 'punt_emergencia_screen.dart';
import 'config.dart';

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
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
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
  bool _isLoading = false;

  // Filtros
  List<String> velocidades = [];
  int potenciaMin = 0;
  int potenciaMax = 400;

  // Filtros seleccionados
  List<String> velocidadesSeleccionadas = [];
  List<String> tiposCargador = [];
  int potenciaMinSeleccionada = 0;
  int potenciaMaxSeleccionada = 400;
  bool filtrarPorCercanas = false;

  //Refugios
  List<Map<String, dynamic>> refugios = [];
  bool mostrarRefugios = false;

  // Add a new list to store selected charger types
  List<String> tiposCargadorSeleccionados = [];

  // Add a new variable to store the selected city
  String ciudadSeleccionada = '';

  @override
  void initState() {
    super.initState();
    _getPosition();
    _fetchEstaciones();
    _fetchFiltros();
    _fetchRefugiosCercanos();
  }

  Future<void> _fetchRefugiosCercanos() async {
    if (myPosition == null) {
      print('Posición no disponible');
      return;
    }

    final url = Uri.parse(
      'http://127.0.0.1:8000/api_punts_carrega/refugios_mas_cercanos/?lat=${myPosition!.latitude}&lng=${myPosition!.longitude}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          refugios =
              data.map((item) {
                final refugio = item['refugio'];
                return {
                  "id_punt": refugio["id_punt"],
                  "lat": refugio["lat"],
                  "lng": refugio["lng"],
                  "nombre": refugio["nombre"],
                  "direccio": refugio["direccio"],
                  "numero_calle": refugio["numero_calle"],
                  "distancia_km": item["distancia_km"],
                };
              }).toList();
        });
      } else {
        print('Error al cargar refugios: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la solicitud de refugios: $e');
    }
  }

  // Modify _fetchFiltros to dynamically fetch charger types
  Future<void> _fetchFiltros() async {
    final url = Uri.parse(
      'http://127.0.0.1:8000/api_punts_carrega/opcions_filtres/',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          velocidades = List<String>.from(data['velocitats']);
          potenciaMin = data['potencia']['min'];
          potenciaMax = data['potencia']['max'];

          potenciaMinSeleccionada = potenciaMin;
          potenciaMaxSeleccionada = potenciaMax;

          // Dynamically fetch charger types
          tiposCargador = List<String>.from(
            data['carregadors'].map((cargador) => cargador['id']),
          );
        });
      } else {
        print('Error al cargar filtros: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la solicitud de filtros: $e');
    }
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
    setState(() {
      _isLoading = true;
    });

    final queryParameters = {
      'potencia_min': potenciaMinSeleccionada.toString(),
      'potencia_max': potenciaMaxSeleccionada.toString(),
    };

    if (velocidadesSeleccionadas.isNotEmpty) {
      queryParameters['velocitat'] = velocidadesSeleccionadas.join(',');
    }

    // Include selected charger types in the query
    if (tiposCargadorSeleccionados.isNotEmpty) {
      queryParameters['tipus_carregador'] = tiposCargadorSeleccionados.join(
        ',',
      );
    }

    // Include the city filter in the query
    if (ciudadSeleccionada.isNotEmpty) {
      queryParameters['ciutat'] = ciudadSeleccionada;
    }

    final uri = Uri.http(
      '127.0.0.1:8000',
      '/api_punts_carrega/filtrar_estacions/',
      queryParameters,
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          estaciones =
              data.map((estacion) {
                return {
                  "id_punt": estacion["id_punt"],
                  "lat": estacion["lat"],
                  "lng": estacion["lng"],
                  "direccio": estacion["direccio"],
                  "ciutat": estacion["ciutat"],
                  "nplaces": estacion["nplaces"],
                  "potencia": estacion["potencia"],
                  "tipus_velocitat": estacion["tipus_velocitat"],
                  "tipus_carregador": estacion["tipus_carregador"],
                };
              }).toList();
          _isLoading = false;
        });
      } else {
        print('Error al cargar datos: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error en la solicitud: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEstacionesCercanas() async {
    if (myPosition == null) {
      print('Posición no disponible');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final uri = Uri.parse(
      'http://127.0.0.1:8000/api_punts_carrega/punt_mes_proper/?lat=${myPosition!.latitude}&lng=${myPosition!.longitude}',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          estaciones =
              data.map((item) {
                final estacion = item['estacio_carrega'];
                return {
                  "id_punt": estacion["id_punt"],
                  "lat": estacion["lat"],
                  "lng": estacion["lng"],
                  "direccio": estacion["direccio"],
                  "ciutat": estacion["ciutat"],
                  "nplaces": estacion["nplaces"],
                  "potencia": estacion["potencia"],
                  "tipus_velocitat": estacion["tipus_velocitat"],
                  "tipus_carregador": estacion["tipus_carregador"],
                  "distancia_km": item["distancia_km"],
                };
              }).toList();
          _isLoading = false;
        });
      } else {
        print('Error al cargar estaciones cercanas: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error en la solicitud de estaciones cercanas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _abrirEstacionScreen(BuildContext context, String idEstacion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EstacionScreen(idStation: idEstacion),
      ),
    );
  }

  void _abrirRefugioScreen(BuildContext context, String idRefugio) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RefugioScreen(idRefugio: idRefugio),
      ),
    );
  }

  Widget _buildEstacionesList() {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                        padding: const EdgeInsets.all(10),
                        children:
                            estaciones
                                .map((estacion) => _buildEstacionCard(estacion))
                                .toList(),
                      ),
            ),
          ],
        ),
        Positioned(
          top: 20,
          left: 10,
          child: FloatingActionButton(
            heroTag: 'filterButtonEstaciones',
            mini: true,
            onPressed: _showFilterBottomSheet,
            backgroundColor: Colors.white,
            child: const Icon(Icons.filter_list, color: Colors.green),
          ),
        ),
      ],
    );
  }

  Widget _buildEstacionCard(Map<String, dynamic> estacion) {
    return InkWell(
      onTap: () {
        _abrirEstacionScreen(context, estacion['id_punt'].toString());
      },
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.ev_station,
                  color: Colors.green,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estacion['direccio'] ?? 'Dirección desconocida',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Ciudad: ${estacion['ciutat'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Builder(
                          builder: (context) {
                            final plazasLibres =
                                (int.tryParse(estacion['nplaces'].toString()) ??
                                    0) >
                                0;
                            return Icon(
                              plazasLibres ? Icons.check_circle : Icons.cancel,
                              color: plazasLibres ? Colors.green : Colors.red,
                              size: 18,
                            );
                          },
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Plazas libres: ${estacion['nplaces'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Potencia: ${estacion['potencia'] ?? 'N/A'} kW',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Velocidad: ${estacion['tipus_velocitat'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    if (estacion.containsKey('distancia_km'))
                      const SizedBox(height: 5),
                    if (estacion.containsKey('distancia_km'))
                      Text(
                        'Distancia: ${estacion['distancia_km'].toStringAsFixed(2)} km',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.green),
                onPressed: () {
                  _abrirEstacionScreen(context, estacion['id_punt'].toString());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  MarkerLayer _buildMarkersLayer() {
    final data = mostrarRefugios ? refugios : estaciones;
    return MarkerLayer(
      markers:
          data
              .map((estacion) {
                final lat = estacion['lat'];
                final lng = estacion['lng'];
                return Marker(
                  width: 40.0,
                  height: 40.0,
                  point: LatLng(lat, lng),
                  builder:
                      (ctx) => Container(
                        child: IconButton(
                          icon: Icon(
                            mostrarRefugios ? Icons.ac_unit : Icons.location_on,
                          ),
                          color: mostrarRefugios ? Colors.blue : Colors.green,
                          iconSize: 25,
                          onPressed: () {
                            if (mostrarRefugios) {
                              _abrirRefugioScreen(
                                context,
                                estacion['id_punt'].toString(),
                              );
                            } else {
                              _abrirEstacionScreen(
                                context,
                                estacion['id_punt'].toString(),
                              );
                            }
                          },
                        ),
                      ),
                );
              })
              .whereType<Marker>()
              .toList(),
    );
  }

  Widget _showMap() {
    final MapController mapController = MapController();

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            center: myPosition,
            minZoom: 5.0,
            maxZoom: 18.0,
            zoom: 16.0,
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
                        (ctx) => Icon(
                          Icons.my_location,
                          color: const Color.fromARGB(255, 255, 0, 0),
                          size: 30,
                        ),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'centerMapButton',
                mini: true,
                onPressed:
                    myPosition == null
                        ? null
                        : () {
                          mapController.move(myPosition!, mapController.zoom);
                        },
                backgroundColor:
                    myPosition == null ? Colors.grey : Colors.white,
                child: const Icon(
                  Icons.location_searching,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'zoomInButton',
                mini: true,
                onPressed: () {
                  mapController.move(
                    mapController.center,
                    (mapController.zoom + 1).clamp(5.0, 18.0),
                  );
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.zoom_in, color: Colors.green),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'zoomOutButton',
                mini: true,
                onPressed: () {
                  mapController.move(
                    mapController.center,
                    (mapController.zoom - 1).clamp(5.0, 18.0),
                  );
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.zoom_out, color: Colors.green),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_selectedIndex == 1) {
        _getPosition();
        _showMap();
      }
    });
  }

  void _navigateToBookingsScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => BookingsScreen()));
  }

  Widget _buildHomePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: _navigateToBookingsScreen,
            borderRadius: BorderRadius.circular(12.0),
            splashColor: Colors.white24,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.calendar_month, color: Colors.white, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'Mis Reservas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update _showFilterBottomSheet to allow multiple charger types selection
  void _showFilterBottomSheet() {
    TextEditingController ciudadController = TextEditingController(
      text: ciudadSeleccionada, // Pre-fill with the selected city
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow the bottom sheet to expand dynamically
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
              ),
              child: Wrap(
                alignment: WrapAlignment.center, // Center the content
                children: [
                  const Center(
                    child: Text(
                      'Filtrar por cercanía',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Mostrar solo estaciones más cercanas'),
                    value: filtrarPorCercanas,
                    onChanged: (bool value) {
                      setModalState(() {
                        filtrarPorCercanas = value;
                        if (filtrarPorCercanas) {
                          velocidadesSeleccionadas.clear();
                          tiposCargadorSeleccionados.clear();
                          potenciaMinSeleccionada = potenciaMin;
                          potenciaMaxSeleccionada = potenciaMax;
                          ciudadController.clear();
                          ciudadSeleccionada = ''; // Clear city filter
                        }
                      });
                    },
                    activeColor: Colors.green,
                  ),
                  if (!filtrarPorCercanas) ...[
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Filtrar por velocidad',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center, // Center the chips
                      spacing: 8.0,
                      runSpacing: 8.0, // Add spacing between rows
                      children:
                          velocidades.map((velocidad) {
                            return FilterChip(
                              label: Text(velocidad),
                              selected: velocidadesSeleccionadas.contains(
                                velocidad,
                              ),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    velocidadesSeleccionadas.add(velocidad);
                                  } else {
                                    velocidadesSeleccionadas.remove(velocidad);
                                  }
                                });
                              },
                              selectedColor: Colors.green.shade100,
                              backgroundColor: Colors.grey.shade200,
                              labelStyle: TextStyle(
                                color:
                                    velocidadesSeleccionadas.contains(velocidad)
                                        ? Colors.green
                                        : Colors.black,
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Filtrar por tipo de cargador',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center, // Center the chips
                      spacing: 8.0,
                      runSpacing: 8.0, // Add spacing between rows
                      children:
                          tiposCargador.map((tipo) {
                            return FilterChip(
                              label: Text(tipo),
                              selected: tiposCargadorSeleccionados.contains(
                                tipo,
                              ),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    tiposCargadorSeleccionados.add(tipo);
                                  } else {
                                    tiposCargadorSeleccionados.remove(tipo);
                                  }
                                });
                              },
                              selectedColor: Colors.green.shade100,
                              backgroundColor: Colors.grey.shade200,
                              labelStyle: TextStyle(
                                color:
                                    tiposCargadorSeleccionados.contains(tipo)
                                        ? Colors.green
                                        : Colors.black,
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Filtrar por potencia (kW)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    RangeSlider(
                      values: RangeValues(
                        potenciaMinSeleccionada.toDouble(),
                        potenciaMaxSeleccionada.toDouble(),
                      ),
                      min: potenciaMin.toDouble(),
                      max: potenciaMax.toDouble(),
                      labels: RangeLabels(
                        "${potenciaMinSeleccionada} kW",
                        "${potenciaMaxSeleccionada} kW",
                      ),
                      onChanged: (RangeValues values) {
                        setModalState(() {
                          potenciaMinSeleccionada = values.start.round();
                          potenciaMaxSeleccionada = values.end.round();
                        });
                      },
                      activeColor: Colors.green,
                      inactiveColor: Colors.grey.shade300,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Min: ${potenciaMinSeleccionada.round()} kW",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Max: ${potenciaMaxSeleccionada.round()} kW",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Filtrar por ciudad',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ciudadController,
                      decoration: const InputDecoration(
                        hintText: 'Introduce el nombre de la ciudad',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          ciudadSeleccionada = value;
                        });
                      },
                      onEditingComplete: () {
                        if (ciudadController.text.isEmpty) {
                          setModalState(() {
                            ciudadSeleccionada = ''; // Clear city filter
                          });
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 70),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (filtrarPorCercanas) {
                          _fetchEstacionesCercanas();
                        } else {
                          _fetchEstaciones();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Aplicar Filtros",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFiltro() {
    return Positioned(
      top: 20,
      left: 10,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: 'filterButton',
            mini: true,
            onPressed: _showFilterBottomSheet,
            backgroundColor: Colors.white,
            child: const Icon(Icons.filter_list, color: Colors.green),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Refugios', style: TextStyle(color: Colors.black)),
              Switch(
                value: mostrarRefugios,
                onChanged: (value) {
                  setState(() {
                    mostrarRefugios = value;
                    if (mostrarRefugios) {
                      _fetchRefugiosCercanos();
                    } else {
                      _fetchEstaciones();
                    }
                  });
                },
                activeColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _selectedIndex == 2
              ? _buildEstacionesList()
              : (_selectedIndex == 1
                  ? Stack(children: [_showMap(), _buildFiltro()])
                  : _buildHomePage()),
          Positioned(
            top: 20.0,
            right: 10.0,
            child: CircleAvatar(
              backgroundColor: Colors.red,
              radius: 20,
              child: IconButton(
                icon: const Icon(Icons.warning, color: Colors.white),
                onPressed: () async {
                  _getPosition(); // Actualizar la posición actual
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return PuntEmergenciaScreen(
                        position: myPosition, // Pasar la posición actual
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
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
