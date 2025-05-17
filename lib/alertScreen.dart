import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'alertManager.dart';

class AlertScreen extends StatelessWidget {
  final double userLat;
  final double userLng;

  const AlertScreen({Key? key, required this.userLat, required this.userLng}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alertManager = Provider.of<AlertManager>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas')),
      body: Center(
        child: Text('Latitud: $userLat, Longitud: $userLng'),
      ),
    );
  }
}