import 'package:flutter/material.dart';
import 'calculate_price.dart';
import 'book_charger.dart';
import 'package:url_launcher/url_launcher.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Set up the theme and other MaterialApp properties as necessary
      home: EstacionScreen(id_station: '12345'), // Use your home screen widget here
    );
  }
}

class EstacionScreen extends StatelessWidget {

  final String id_station;

  const EstacionScreen({super.key, required this.id_station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Estación {parametre}')),

      body: Padding(
        padding: EdgeInsets.all(30.0),
        child: Column(
          children: [
            Row(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tipo de enchufe: ',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '{Parametre}',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Potencia: ',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '{Parametre}',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Estado: ',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '{Parametre}',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Dirección: ',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '{Parametre}',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 60,
            ),
            TextButton(
              onPressed: () => _openGoogleMaps(41.58138888888, 1.620833333333),
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF2C8235),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13), // Rounded corners
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Cómo llegar'),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChargeCalculatorScreen(
                      tipoCarga: 'Carga rápida',
                      precio: '3 €',
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF54a0e8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13), // Rounded corners
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.money, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Calcular precio'),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BookChargerScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFa955e0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13), // Rounded corners
                ),
              ),
              child: Row(
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

  Future<void> _openGoogleMaps(double destinationLatitude, double destinationLongitude) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$destinationLatitude,$destinationLongitude';
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

}
