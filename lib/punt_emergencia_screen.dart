import 'package:eco_move_frontend/noti_service.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'EmergenciaDetails.dart';

class PuntEmergenciaScreen extends StatelessWidget {
  final LatLng? position; // Recibir la posición como parámetro
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

   PuntEmergenciaScreen({Key? key, this.position}) : super(key: key);

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  Future<void> _sendEmergency(
      BuildContext context, String title, String description) async {
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación no disponible')),
      );
      return;
    }

    final url = Uri.parse('${AppConfig.apiBase}/social/alerts/');
    final token = await getAccessToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token no disponible')),
      );
      return;
    }

    final Map<String, dynamic> data = {
      'titol': title,
      'descripcio': description,
      'lat': position!.latitude,
      'lng': position!.longitude,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerta enviada con éxito')),
        );
        //Navigator.of(context).pop();
      } else if (response.statusCode == 401) {
        String? refreshToken = await _secureStorage.read(key: 'refresh');
        if (refreshToken != null) {
          await _refreshToken(refreshToken, context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autenticación requerida')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  Future<void> _refreshToken(String refreshToken, BuildContext context) async {
    final url = Uri.parse('${AppConfig.apiBase}/token/refresh/');
    final Map<String, dynamic> data = {'refresh': refreshToken};

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> resp = json.decode(response.body);
        await _secureStorage.write(key: 'access', value: resp['access']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token actualizado. Intenta de nuevo.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el token')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController tituloController = TextEditingController();
    TextEditingController descripcionController = TextEditingController();

    return AlertDialog(
      title: const Text("Enviar alerta"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: tituloController,
            decoration: const InputDecoration(
              labelText: "Título",
              hintText: "Título",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descripcionController,
            decoration: const InputDecoration(
              labelText: "Descripción",
              hintText: "Descripción",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
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
            _sendEmergency(
              context,
              tituloController.text,
              descripcionController.text,
            );

             /*Navegar directamente a la nueva página
             Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EmergenciaDetails()),
              );
              */
            /*NotiService().showNotification(
               title: "Alerta enviada",
               body: "Tu alerta ha sido enviada con éxito.",
               payload: "navigate_to_screen",
            );
            */
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("Enviar"),
        ),
      ],
    );
  }
}