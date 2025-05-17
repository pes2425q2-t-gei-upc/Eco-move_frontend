import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'routes/frontend_routes.dart';

class NotificarErrorScreen extends StatefulWidget {
  final String idStation;
  const NotificarErrorScreen({Key? key, required this.idStation}) : super(key: key);

  @override
  State<NotificarErrorScreen> createState() => _NotificarErrorScreenState();
}

class _NotificarErrorScreenState extends State<NotificarErrorScreen> {
  List<dynamic> tiposError = [];
  String? tipoSeleccionado;
  final TextEditingController comentarioController = TextEditingController();
  bool isLoading = true;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchTiposError();
  }

  Future<void> fetchTiposError() async {
    final url = Uri.parse(
  FrontendRoutes.build(FrontendRoutes.tiposErrorEstacion),
);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          tiposError = json.decode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> getAccessToken() async {
  return await _secureStorage.read(key: 'access');
}

  Future<void> _enviarErrorApi() async {
    final token = await getAccessToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token no disponible')),
      );
      return;
    }

    final url = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.reportarErrorEstacion(widget.idStation)),
    );

    final Map<String, dynamic> data = {
      'tipo_error': tipoSeleccionado,
      'comentario_usuario': comentarioController.text,
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

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error reportado con éxito')),
        );
        setState(() {
          tipoSeleccionado = null;
          comentarioController.clear();
        });
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión expirada. Vuelve a iniciar sesión.')),
        );
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificar error')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecciona el tipo de error:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      items: tiposError.map<DropdownMenuItem<String>>((tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo['valor'],
                          child: Text(tipo['display']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          tipoSeleccionado = value;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Selecciona un error',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'Descripción o comentario (opcional):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: comentarioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Describe el problema...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Enviar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 23, 51, 209),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: tipoSeleccionado == null ? null : _enviarErrorApi,
            ),
          ),
        ),
      ),
    );
  }
}