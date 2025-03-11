import 'package:flutter/material.dart';

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

  final List<Map<String, String>> estaciones = [
    {'id': '1', 'nombre': 'Estación Centro', 'ubicacion': 'Calle A, Ciudad X'},
    {
      'id': '2',
      'nombre': 'Carga Rápida Norte',
      'ubicacion': 'Avenida B, Ciudad Y',
    },
    {'id': '3', 'nombre': 'Punto Verde', 'ubicacion': 'Plaza C, Ciudad Z'},
  ];

  Widget _buildEstacionCard(Map<String, String> estacion) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${estacion['id']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Nombre: ${estacion['nombre']}'),
            Text('Ubicación: ${estacion['ubicacion']}'),
          ],
        ),
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
      body: ListView(
        padding: const EdgeInsets.all(10),
        children:
            estaciones.map((estacion) => _buildEstacionCard(estacion)).toList(),
      ),
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
    );
  }
}
