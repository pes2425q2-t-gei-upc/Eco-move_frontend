import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';

class AlertDialogPage extends StatelessWidget {
  final LatLng? position; // Recibir la posición como parámetro

  const AlertDialogPage({Key? key, this.position}) : super(key: key);

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
              hintText:
                  context
                      .loc
                      .common_title, // Ensure the placeholder remains constant
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descripcionController,
            decoration: InputDecoration(
              labelText: context.loc.common_description,
              hintText:
                  context
                      .loc
                      .common_description, // Ensure the placeholder remains constant
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
            print("Título: ${tituloController.text}");
            print("Descripción: ${descripcionController.text}");
            if (position != null) {
              print(
                'Ubicación: Latitud ${position!.latitude}, Longitud ${position!.longitude}',
              );
            } else {
              print('Ubicación no disponible');
            }
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(context.loc.common_send),
        ),
      ],
    );
  }
}
