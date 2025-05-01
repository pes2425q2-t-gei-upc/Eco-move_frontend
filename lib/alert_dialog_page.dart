import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class AlertDialogPage extends StatelessWidget {
  final LatLng? position; // Recibir la posición como parámetro

  const AlertDialogPage({Key? key, this.position}) : super(key: key);

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
              hintText: "Título", // Ensure the placeholder remains constant
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descripcionController,
            decoration: const InputDecoration(
              labelText: "Descripción",
              hintText:
                  "Descripción", // Ensure the placeholder remains constant
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
          child: const Text("Enviar"),
        ),
      ],
    );
  }
}
