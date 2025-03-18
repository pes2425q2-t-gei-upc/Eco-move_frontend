import 'package:flutter/material.dart';

class ChargeCalculatorScreen extends StatefulWidget {
  final String tipoCarga;
  final String precio;

  const ChargeCalculatorScreen({
    super.key,
    required this.tipoCarga,
    required this.precio});


  @override
  ChargeCalculatorScreenState createState() => ChargeCalculatorScreenState();
}

class ChargeCalculatorScreenState extends State<ChargeCalculatorScreen> {
  final TextEditingController batteryCapacityController = TextEditingController();
  final TextEditingController currentPercentageController = TextEditingController();
  final TextEditingController desiredPercentageController = TextEditingController();

  void _showPriceDialog(double price) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Precio de carga'),
          content: Text('El precio total es: €${price.toStringAsFixed(2)}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _calculatePrice() {
    double batteryCapacity = double.tryParse(batteryCapacityController.text) ?? 0;
    double currentPercentage = double.tryParse(currentPercentageController.text) ?? 0;
    double desiredPercentage = double.tryParse(desiredPercentageController.text) ?? 0;

    if (batteryCapacity > 0 && currentPercentage >= 0 && desiredPercentage > currentPercentage) { //POSAR MÉS CONDICIONS
      double energyRequired = (desiredPercentage - currentPercentage) / 100 * batteryCapacity;
      double price = energyRequired * 0.20;

      _showPriceDialog(price);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid values')),
      );
    }
  }

  @override
  void dispose() {
    batteryCapacityController.dispose();
    currentPercentageController.dispose();
    desiredPercentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Calcular precio de carga')),
      body: Padding(
        padding: EdgeInsets.all(30.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Color(0xffbcccf7),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Tipo de carga: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(widget.tipoCarga),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Precio: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(widget.precio),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Capacidad de la batería (kWh)'),
            ),
            TextField(
              controller: batteryCapacityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ej: 60',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 25),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Porcentaje actual de la bateria (%)'),
            ),
            TextField(
              controller: currentPercentageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ej: 20',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 25),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Porcentaje deseado de carga (%)'),
            ),
            TextField(
              controller: desiredPercentageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ej: 80',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: _calculatePrice,
              style: TextButton.styleFrom(
                backgroundColor: Color(0xff6d89d6),
                foregroundColor: Colors.white,
              ),
              child: Text('Calcular precio'),
            ),
          ],
        ),
      ),
    );
  }
}
