import 'dart:convert';
import 'package:eco_move_frontend/calendar.dart';
import 'package:eco_move_frontend/get_bookings.dart';
import 'package:eco_move_frontend/l10n/l10n.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:eco_move_frontend/list_chats.dart';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'gestio_reserva.dart';
import 'package:geolocator/geolocator.dart';
import 'log_in.dart';
import 'refugio_screen.dart';
import 'punt_emergencia_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'l10n/locale_provider.dart';
import 'settings-menu.dart';
import 'noti_service.dart';
import 'EmergencyScreen.dart';
import 'EmergencyService.dart';
import 'bici_detail_screen.dart';
import 'bici_reservas_screen.dart'; 
import 'config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa las notificaciones
  NotiService().iniNotification();

  // Obtiene las preferencias del idioma
  final prefs = await SharedPreferences.getInstance();
  final langCode = prefs.getString('Language') ?? 'en';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(Locale(langCode))), // Inicializa LocaleProvider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey, // Configura el GlobalKey aquí
      title: 'ECO-MOVE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green[300]!),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xff4a7c59),
          foregroundColor: Colors.white,
        ),
      ),
      locale: provider.locale,
      supportedLocales: L10n.all,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/list-chats': (context) => ChatListScreen(),
        // ...otras rutas...
      },
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
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final EmergencyService _emergencyService = EmergencyService();
  final NotiService _notiService = NotiService();

  int _selectedIndex = 0;
  List<Map<String, dynamic>> estaciones = [];
  LatLng? myPosition;
  String filtroSeleccionado = 'all';
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

  //Bicis
  List<dynamic> _bicis = [];
  String _tipoMapa = 'estaciones'; // valores: 'estaciones', 'refugios', 'bicis'

  // Add a new list to store selected charger types
  List<String> tiposCargadorSeleccionados = [];

  // Add a new variable to store the selected city
  String ciudadSeleccionada = '';

  bool _isPollingStarted = false; // Variable de control para evitar múltiples inicios
  LatLng? _pollingPosition; // Posición utilizada en el polling

  bool filtrarPorCoche = false;
  
  @override
  void initState() {
    super.initState();
    _getPosition();
    _fetchEstaciones();
    _fetchFiltros();
    _fetchRefugiosCercanos();
  }

  void _startPollingForEmergencies() {
    if (_isPollingStarted) return; // Evita múltiples inicios
    _isPollingStarted = true;

    _emergencyService
        .pollForNewEmergencyPointsStream(() => _pollingPosition) // Usa una función para obtener la posición actualizada
        .listen((newPoint) {
      if (newPoint != null) {
        _notiService.showNotification(
          title: "Nuevo Punto de Emergencia",
          body: "Se ha detectado un nuevo punto de emergencia: ${newPoint.title}",
          payload: "navigate_to_screen|${newPoint.title}|${newPoint.description}|${newPoint.lat}|${newPoint.lng}|${newPoint.timestamp}|${newPoint.sender}",
        );
      }
    });
  }

  void _getPosition() async {
    Position? position = await _determinePosition();
    if (position != null) {
      print("Posición obtenida: ${position.latitude}, ${position.longitude}");
      setState(() {
        myPosition = LatLng(position.latitude, position.longitude);
        _pollingPosition = myPosition; // Actualiza la posición utilizada en el polling
      });

      if (!_isPollingStarted) {
        _startPollingForEmergencies(); // Inicia el polling solo una vez
      }
    }
  }



  Future<void> _fetchRefugiosCercanos() async {
    if (myPosition == null) {
      print('Posición no disponible');
      return;
    }

    final url = Uri.parse(
      'http://nattech.fib.upc.edu:40430/api/refugios/listar_cercania/${myPosition!.latitude}/${myPosition!.longitude}/'
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print(data);
        setState(() {
          refugios =
              data.map((item) {
                final refugio = item;
                return {
                  "id_punt": refugio["id"],
                  "lat": refugio["latitud"],
                  "lng": refugio["longitud"],
                  "nombre": refugio["nombre"],
                  "direccio": refugio["direccion"],
                  "numero_calle": refugio["numero_calle"],
                  "distancia_km": item["distancia"],
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

  Future<void> _fetchBicis() async {
  final url = Uri.parse(
    FrontendRoutes.build(FrontendRoutes.biciDetailBase),
  );
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _bicis = data.map((item) {
    return {
      "id": item["id"],
      "lat": item["lat"],
      "lng": item["lon"],
    };
        }).toList();
      });
    } else {
      print('Error al cargar bicis: ${response.statusCode}');
    }
  } catch (e) {
    print('Error en la solicitud de bicis: $e');
  }
}

Future<List<String>> fetchCargadoresCoche() async {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final String? token = await _secureStorage.read(key: 'access');
  if (token == null) {
    print('Token no disponible');
    return [];
  }

    final url = Uri.parse('${AppConfig.apiBase}/api_punts_carrega/vehicles/');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Extrae todos los cargadores de todos los coches y los pone en una sola lista (sin duplicados)
        final Set<String> cargadores = {};
        for (var coche in data) {
          if (coche['tipus_carregador'] != null) {
            cargadores.addAll(List<String>.from(coche['tipus_carregador']));
          }
        }
        return cargadores.toList();
      } else {
        print('Error al cargar vehículos: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error en la solicitud de vehículos: $e');
      return [];
    }
  }

  Future<void> _fetchFiltros() async {
    final url = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.opcionsFiltres),
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

    final uri = Uri.parse(FrontendRoutes.build(FrontendRoutes.filtrarEstacions))
      .replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

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
                  "fuera_de_servicio": estacion["fuera_de_servicio"],

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
      '${FrontendRoutes.build(FrontendRoutes.puntmesproper)}?lat=${myPosition!.latitude}&lng=${myPosition!.longitude}',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
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

  void _abrirRefugioScreen(BuildContext context, String idRefugio, double? distanciaKm) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RefugioScreen(idRefugio: idRefugio,distanciaKm: distanciaKm,),
      ),
    );
  }

void _abrirBiciScreen(BuildContext context, String idBici) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => BiciDetailScreen(idBici: idBici),
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
            child: const Icon(Icons.filter_list, color: Color(0xff4a7c59)),
          ),
        ),
      ],
    );
  }

  Widget _buildEstacionCard(Map<String, dynamic> estacion) {
    final bool fueraDeServicio = estacion['fuera_de_servicio'] == true;

    return InkWell(
      onTap: () {
        if (fueraDeServicio) {
          return;
        }
        _abrirEstacionScreen(context, estacion['id_punt'].toString());
      },
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: fueraDeServicio ? Colors.grey.shade200 : Colors.white,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: fueraDeServicio ? Colors.red.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.ev_station,
                      color: fueraDeServicio ? Colors.red :Color(0xff4a7c59),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estacion['direccio'] ?? context.loc.station_address_unknown,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${context.loc.station_city}: ${estacion['ciutat'] ?? 'N/A'}',
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
                              '${context.loc.station_free_spots}: ${estacion['nplaces'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${context.loc.station_power}: ${estacion['potencia'] ?? 'N/A'} kW',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${context.loc.station_speed_type}: ${estacion['tipus_velocitat'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        if (estacion.containsKey('distancia_km'))
                          const SizedBox(height: 5),
                        if (estacion.containsKey('distancia_km'))
                          Text(
                            '${context.loc.station_distance}: ${estacion['distancia_km'].toStringAsFixed(2)} km',
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
                    icon: Icon(Icons.arrow_forward, 
                    color: fueraDeServicio ? Colors.grey : Colors.green
                    ),
                    tooltip: fueraDeServicio ? context.loc.out_of_service : null,
                    onPressed: () {
                      if (fueraDeServicio) {
                        return;
                      }
                      _abrirEstacionScreen(context, estacion['id_punt'].toString());
                    },
                  ),
                ],
              ),
            ),
            // Out of service label
            if (fueraDeServicio)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        context.loc.out_of_service ,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

 MarkerLayer _buildMarkersLayer() {
  List<dynamic> data;
  if (_tipoMapa == 'refugios') {
    data = refugios;
  } else if (_tipoMapa == 'bicis') {
    data = _bicis;
  } else {
    data = estaciones;
  }
  return MarkerLayer(
    markers: data.map((estacion) {
      final lat = estacion['lat'];
      final lng = estacion['lng'];
      IconData iconData;
      Color borderColor;

      if (_tipoMapa == 'refugios') {
        iconData = Icons.ac_unit;
        borderColor = Colors.lightBlueAccent;
      } else if (_tipoMapa == 'bicis') {
        iconData = Icons.pedal_bike;
        borderColor = Colors.orange;
      } else {
        iconData = Icons.ev_station;
        borderColor = Colors.green;
      }

      return Marker(
        width: 28.0,
        height: 28.0,
        point: LatLng(double.tryParse(estacion['lat'].toString()) ?? 0.0, double.tryParse(estacion['lng'].toString()) ?? 0.0),
        builder: (ctx) => GestureDetector(
          onTap: () {
            if (_tipoMapa == 'refugios') {
              _abrirRefugioScreen(context, estacion['id_punt'].toString(), (estacion['distancia_km'] as num?)?.toDouble());
            } else if (_tipoMapa == 'bicis') {
              _abrirBiciScreen(context, estacion['id'].toString());
            } else {
              _abrirEstacionScreen(context, estacion['id_punt'].toString());
            }
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                iconData,
                color: borderColor,
                size: 15,
              ),
            ),
          ),
        ),
      );
    }).toList(),
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
      child: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco, color: Color(0xff4a7c59), size: 60),
                  const SizedBox(height: 24),
                  Text(
                    context.loc.home_welcome,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Color(0xff4a7c59),
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const BiciReservasScreen()),
                      );
                    },
                    icon: const Icon(Icons.pedal_bike),
                    label: Text(context.loc.home_bicis),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _navigateToBookingsScreen,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(context.loc.home_my_reservations),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff4a7c59),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EmergencyScreen(
                            userLat: myPosition?.latitude ?? 0.0,
                            userLng: myPosition?.longitude ?? 0.0,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    label:  Text(context.loc.home_emergency),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Update _showFilterBottomSheet to allow multiple charger types selection
  void _showFilterBottomSheet() {
    TextEditingController ciudadController = TextEditingController(
      text: ciudadSeleccionada,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
              return Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
              ),
              child: SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.place, color: Color(0xff4a7c59)),
                        const SizedBox(width: 8),
                        Text(
                          context.loc.filter_by_proximity,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff4a7c59),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: Text(context.loc.filter_show_only_nearest_stations),
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
                          ciudadSeleccionada = '';
                          filtrarPorCoche = false;
                        }
                      });
                    },
                    activeColor: Color(0xff4a7c59),
                  ),
                  if (!filtrarPorCercanas) ...[
                    const SizedBox(height: 20),
                    Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car, color: Color(0xff4a7c59)),
                        const SizedBox(width: 8),
                        Text(
                          context.loc.filter_by_car,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff4a7c59),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: Text(context.loc.filter_show_only_car_compatible),
                    value: filtrarPorCoche,
                    onChanged: (bool value) async {
                      setModalState(() {
                        filtrarPorCoche = value;
                      });
                      if (value) {
                        final cargadores = await fetchCargadoresCoche();
                        setModalState(() {
                          for (final cargador in cargadores) {
                            if (!tiposCargadorSeleccionados.contains(cargador)) {
                              tiposCargadorSeleccionados.add(cargador);
                            }
                          }
                        });
                      }
                      else {
                        final cargadores = await fetchCargadoresCoche();
                        setModalState(() {
                          tiposCargadorSeleccionados.removeWhere((cargador) => cargadores.contains(cargador));
                        });
                      }
                    },
                    activeColor: Color(0xff4a7c59),
                  ),
                    Center(
                      child: Text(
                        context.loc.filter_by_speed,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff4a7c59),
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
                                        ? Color(0xff4a7c59)
                                        : Colors.black,
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        context.loc.filter_by_charger_type,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff4a7c59),
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
                                        ? Color(0xff4a7c59)
                                        : Colors.black,
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '${context.loc.filter_by_power} (kW)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff4a7c59),
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
                      activeColor:Color(0xff4a7c59),
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
                    Center(
                      child: Text(
                        context.loc.filter_by_city,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff4a7c59),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ciudadController,
                      decoration: InputDecoration(
                        hintText:
                            context.loc.station_enter_the_name_of_the_city,
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
                        backgroundColor: Color(0xff4a7c59),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.loc.filter_apply_filter,
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  },
  );
  }

 Widget _buildFiltro() {
  final opciones = [
    {
      'value': 'estaciones',
      'icon': Icons.ev_station,
      'tooltip': 'Estaciones de carga',
      'color': Color(0xff4a7c59),
      'label': context.loc.charging_stations
    },
    {
      'value': 'refugios',
      'icon': Icons.ac_unit,
      'tooltip': 'Refugios climáticos',
      'color': Colors.lightBlueAccent,
      'label': context.loc.climate_shelters
    },
    {
      'value': 'bicis',
      'icon': Icons.pedal_bike,
      'tooltip': 'Bicing',
      'color': Colors.orange,
      'label': context.loc.bike_stations
    },
  ];

  return Positioned(
    top: 20,
    left: 10,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FloatingActionButton(
          heroTag: 'filterButton',
          mini: true,
          onPressed: _showFilterBottomSheet,
          backgroundColor: Colors.white,
          child: const Icon(Icons.filter_list, color: Color(0xff4a7c59)),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 36,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: opciones.map((opcion) {
                final bool selected = _tipoMapa == (opcion['value'] as String);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Tooltip(
                      message: opcion['tooltip'] as String,
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              opcion['icon'] as IconData,
                              size: 22,
                              color: selected
                                  ? opcion['color'] as Color
                                  : Colors.black45,
                            ),
                            if (selected) ...[
                              SizedBox(height: 1),
                              Flexible(
                                child: Text(
                                  opcion['label'] as String, // Add 'label' field to your opciones data
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                    color: opcion['color'] as Color,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: (opcion['color'] as Color).withOpacity(0.18),
                    backgroundColor: Colors.grey.shade200,
                    onSelected: (isSelected) {
                      if (isSelected) {
                        setState(() {
                          _tipoMapa = opcion['value'] as String;
                          if (_tipoMapa == 'estaciones') {
                            _fetchEstaciones();
                          } else if (_tipoMapa == 'refugios') {
                            _fetchRefugiosCercanos();
                          } else if (_tipoMapa == 'bicis') {
                            _fetchBicis();
                          }
                        });
                      }
                    },
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ),
  );
}

  Future<void> deleteTokens() async {
    try {
      await _secureStorage.delete(key: 'access');
      await _secureStorage.delete(key: 'refresh');
      print('Tokens deleted successfully');
    } catch (e) {
      print('Error deleting tokens: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => NavigationPage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(context.loc.logout_sign_out),
                    content: Text(
                      context.loc.logout_are_you_sure,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: Text(context.loc.common_cancel),
                      ),
                      TextButton(
                        onPressed: () async {
                          // clear tokens
                          await deleteTokens();
                          await _secureStorage.deleteAll();

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('Language', 'en');

                          // Reset locale
                          Provider.of<LocaleProvider>(navigatorKey.currentContext!, listen: false)
                            .setLocale(const Locale('en'));

                          // Navigate back to login screen
                          Navigator.of(context).pop(); // Close the dialog
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                                (Route<dynamic> route) => false,
                          );
                        },
                        child: Text(context.loc.logout_sign_out),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
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
            child: Column(
              children: [
                CircleAvatar(
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
                const SizedBox(height: 10), // Space between the buttons
                CircleAvatar(
                  backgroundColor: Color(0xff4a7c59),
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.chat, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatListScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    bottomNavigationBar: BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: context.loc.nav_home,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.map),
          label: context.loc.nav_map,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.ev_station),
          label: context.loc.nav_stations,
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Color(0xff4a7c59),
      onTap: _onItemTapped,
    ),
  );
}
}
