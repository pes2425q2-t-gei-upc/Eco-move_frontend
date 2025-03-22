import 'package:flutter/material.dart';
import 'calculate_price.dart';
import 'book_charger.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EstacionScreen(idStation: '12345'),
    );
  }
}

class EstacionScreen extends StatefulWidget {
  final String idStation;

  const EstacionScreen({required this.idStation, super.key});

  @override
  State<EstacionScreen> createState() => _EstacionScreenState();
}

class _EstacionScreenState extends State<EstacionScreen> {
  final Map<String, dynamic> stationData = {
    'id': '12345',
    'tipoEnchufe': ['Tesla', 'Schuko'],
    'potencia': ['22 kW', '7 kW'],
    'estado': 'Disponible',
    'direccion': 'Avinguda Barcelona 48',
    'precio': '3 €',
  };

  int? selectedIndex;

  void _selectButton(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Estación ${stationData['id']}')),

      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Tipo de enchufe: ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(
                    stationData['tipoEnchufe'].length,
                        (index) {
                      String tipo = stationData['tipoEnchufe'][index];
                      bool isSelected = selectedIndex == index;

                      return ElevatedButton(
                        onPressed: () => _selectButton(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? Colors.blueGrey : Colors.white,
                          foregroundColor: isSelected ? Colors.white : Colors.blueGrey,
                          side: const BorderSide(
                            color: Colors.blueGrey,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(tipo),
                    );
                  },
                ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Potencia: ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  selectedIndex != null && selectedIndex! < stationData['potencia'].length
                      ? stationData['potencia'][selectedIndex!]
                      : stationData['potencia'][0],
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Estado: ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  stationData['estado'],
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Dirección: ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  stationData['direccion'],
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 60,
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF2C8235),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13), // Rounded corners
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Cómo llegar'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                 Navigator.of(context).push(
                   MaterialPageRoute(
                     builder: (context) => ChargeCalculatorScreen(
                       tipoCarga: selectedIndex != null && selectedIndex! < stationData['potencia'].length
                           ? stationData['potencia'][selectedIndex!]
                           : stationData['potencia'][0],
                       precio: stationData['precio'],
                     ),
                   ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF54a0e8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13), // Rounded corners
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.money, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Calcular precio'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                   MaterialPageRoute(
                     builder: (context) => BookChargerScreen(),
                   ),
                 );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFa955e0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13), // Rounded corners
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Reservar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}