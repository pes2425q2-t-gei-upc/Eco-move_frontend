import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'routes/frontend_routes.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';

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

  final Map<String, Map<String, String>> tiposErrorTraducciones = {
    'NO_FUNCIONA': {
      'es': 'No funciona / Sin energía',
      'en': 'Not working / No power',
      'ca': 'No funciona / Sense energia',
    },
    'CARGA_LENTA': {
      'es': 'Carga inesperadamente lenta',
      'en': 'Unexpectedly slow charging',
      'ca': 'Càrrega inesperadament lenta',
    },
    'CONECTOR_DANADO': {
      'es': 'Conector dañado o bloqueado',
      'en': 'Damaged or blocked connector',
      'ca': 'Connector danyat o bloquejat',
    },
    'PANTALLA_APAGADA': {
      'es': 'Pantalla apagada o ilegible',
      'en': 'Screen off or unreadable',
      'ca': 'Pantalla apagada o il·legible',
    },
    'PAGO_FALLIDO': {
      'es': 'Problema con el sistema de pago',
      'en': 'Payment system problem',
      'ca': 'Problema amb el sistema de pagament',
    },
    'OBSTACULO_FISICO': {
      'es': 'Obstáculo físico / Plaza bloqueada',
      'en': 'Physical obstacle / Blocked spot',
      'ca': 'Obstacle físic / Plaça bloquejada',
    },
    'OTRO': {
      'es': 'Otro problema (ver comentario)',
      'en': 'Other problem (see comment)',
      'ca': 'Altre problema (vegeu comentari)',
    },
  };

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
         SnackBar(content: Text(context.loc.notificar_error_token_missing)),
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
           SnackBar(content: Text(context.loc.notificar_error_success)),
        );
        setState(() {
          tipoSeleccionado = null;
          comentarioController.clear();
        });
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.notificar_error_session_expired)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.loc.notificar_error_error}: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.loc.notificar_error_connection_error}: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final String lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(context.loc.notificar_error_title)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.notificar_error_select_type,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      items: tiposError.map<DropdownMenuItem<String>>((tipo) {
                        final valor = tipo['valor'];
                        final display = tiposErrorTraducciones[valor]?[lang] ?? tipo['display'];
                        return DropdownMenuItem<String>(
                          value: valor,
                          child: Text(display),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          tipoSeleccionado = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: context.loc.notificar_error_description_hint,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    Text(
                      context.loc.notificar_error_description_label,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: comentarioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: context.loc.notificar_error_description_hint,
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
              label: Text(context.loc.common_send),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4a7c59),
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