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
        //Navigator.of(context).pop();
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
      title: Text(context.loc.alert_send_alert),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: tituloController,
            decoration: InputDecoration(
              labelText: context.loc.common_title,
              hintText: context.loc.common_title,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descripcionController,
            decoration: InputDecoration(
              labelText: context.loc.common_description,
              hintText: context.loc.common_description,
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
          child: Text(context.loc.common_cancel),
        ),
        TextButton(
          onPressed: () {
            _sendEmergency(
              context,
              tituloController.text,
              descripcionController.text,
            );
             Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(context.loc.common_send),
        ),
      ],
    );
  }
}