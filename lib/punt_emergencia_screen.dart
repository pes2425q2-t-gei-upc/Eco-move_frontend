import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';

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

    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.alerts));
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
          SnackBar(content: Text(context.loc.alert_sent_successfully)),
        );
        Navigator.of(context).pop();
      } else if (response.statusCode == 401) {
        String? refreshToken = await _secureStorage.read(key: 'refresh');
        if (refreshToken != null) {
          await _refreshToken(refreshToken, context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.loc.alert_authentication_required)),
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
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.tokenRefresh));
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.loc.alert_send_alert,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloController,
              decoration: InputDecoration(
                labelText: context.loc.common_title,
                hintText: context.loc.common_title,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descripcionController,
              decoration: InputDecoration(
                labelText: context.loc.common_description,
                hintText: context.loc.common_description,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(context.loc.common_cancel),
        ),
        ElevatedButton.icon(
          onPressed: () {
            _sendEmergency(
              context,
              tituloController.text,
              descripcionController.text,
            );
          },
          icon: const Icon(Icons.send, color: Colors.white),
          label: Text(context.loc.common_send, style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}