import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'routes/frontend_routes.dart';
import 'bici_detail_screen.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:intl/intl.dart';

class BiciReservasScreen extends StatefulWidget {
  const BiciReservasScreen({super.key});

  @override
  State<BiciReservasScreen> createState() => _BiciReservasScreenState();
}

class _BiciReservasScreenState extends State<BiciReservasScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  List<dynamic> reservasActivas = [];
  List<dynamic> reservasHistorial = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReservas();
  }

  String formatFechaHora(String fechaIso) {
    final date = DateTime.parse(fechaIso).toLocal();
    final fecha = DateFormat('dd/MM/yyyy').format(date);
    final hora = DateFormat('HH:mm').format(date);
    return '$fecha $hora h';
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

 Future<void> fetchReservas() async {
    final token = await getAccessToken();
    if (token == null) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.notificar_error_token_missing)),
      );
      return;
    }

    try {
      // Reservas activas
      final urlActivas = Uri.parse(FrontendRoutes.build(FrontendRoutes.biciReservasActivas));
      final responseActivas = await http.get(
        urlActivas,
        headers: {'Authorization': 'Bearer $token'},
      );

      // Historial
      final urlHistorial = Uri.parse(FrontendRoutes.build(FrontendRoutes.biciReservasHistorial));
      final responseHistorial = await http.get(
        urlHistorial,
        headers: {'Authorization': 'Bearer $token'},
      );

      setState(() {
        reservasActivas = responseActivas.statusCode == 200
            ? json.decode(responseActivas.body)
            : [];
        reservasHistorial = responseHistorial.statusCode == 200
            ? json.decode(responseHistorial.body)
            : [];
        isLoading = false;
      });

      if (responseActivas.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.bici_reservas_error_activas(responseActivas.body))),
        );
      }
      if (responseHistorial.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.bici_reservas_error_historial(responseHistorial.body))),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:  Text(context.loc.bici_reservas_error_conexion(e.toString()))),
      );
    }
  }

  Future<void> cancelarReserva(dynamic reservaId) async {
    final token = await getAccessToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.notificar_error_token_missing)),
      );
      return;
    }

    final urlCancelar = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.biciReservaCancelar(reservaId.toString()))
    );
    try {
      final response = await http.delete(
        urlCancelar,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.bici_reservas_cancelada_ok)),
        );
        fetchReservas(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.bici_reservas_error_cancelar(response.body))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.bici_reservas_error_conexion(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.bici_reservas_title),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (reservasActivas.isEmpty && reservasHistorial.isEmpty)
              ? Center(
                  child: Text(
                    context.loc.bici_reservas_no_reservas,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchReservas,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      if (reservasActivas.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_bike, color: Colors.green, size: 28),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  context.loc.bici_reservas_activas,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...reservasActivas.map((reserva) => AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.lock_open, color: Colors.green, size: 32),
                                title: Text(
                                  reserva['estacion'] != null
                                      ? '${context.loc.bici_detail_title}: ${reserva['estacion']}'
                                      : context.loc.bici_reservas_activas,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${context.loc.bici_reserva_tipo_bicicleta} ${reserva['tipo_bicicleta']}'),
                                    Text('${context.loc.bici_reserva_creada_en} ${formatFechaHora(reserva['creada_en'])}'),
                                    Text('${context.loc.bici_reserva_expira} ${formatFechaHora(reserva['expiracion'])}'),
                                    Text('${context.loc.bici_reserva_activa} ${reserva['activa']}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.black),
                                  tooltip: context.loc.bici_reservas_cancelar,
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(context.loc.bici_reservas_confirm_cancel_title),
                                        content: Text(context.loc.bici_reservas_confirm_cancel_content),
                                        actions: [
                                          TextButton(
                                            child: Text(
                                              context.loc.bici_reservas_confirm_cancel_no,
                                              style: const TextStyle(color: Colors.black), // <-- texto negro
                                            ),
                                            onPressed: () => Navigator.of(context).pop(false),
                                          ),
                                          ElevatedButton(
                                            child: Text(
                                              context.loc.bici_reservas_confirm_cancel_si,
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () => Navigator.of(context).pop(true),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await cancelarReserva(reserva['id']);
                                    }
                                  },
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                onTap: () {
                                  final idEstacion = reserva['estacion'].toString();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => BiciDetailScreen(idBici: idEstacion),
                                    ),
                                  );
                                },
                              ),
                            )),
                      ],
                      if (reservasHistorial.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.history, color: Colors.orange, size: 28),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  context.loc.bici_reservas_historial,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...reservasHistorial.map((reserva) => AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.lock, color: Colors.orange, size: 32),
                                title: Text(
                                  reserva['estacion'] != null
                                      ? '${context.loc.bici_detail_title}: ${reserva['estacion']}'
                                      : context.loc.bici_reservas_historial,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${context.loc.bici_reserva_tipo_bicicleta} ${reserva['tipo_bicicleta']}'),
                                    Text('${context.loc.bici_reserva_creada_en} ${formatFechaHora(reserva['creada_en'])}'),
                                    Text('${context.loc.bici_reserva_expira} ${formatFechaHora(reserva['expiracion'])}'),
                                    Text('${context.loc.bici_reserva_activa} ${reserva['activa']}'),
                                  ]
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                onTap: () {
                                  final idEstacion = reserva['estacion'].toString();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => BiciDetailScreen(idBici: idEstacion),
                                    ),
                                  );
                                },
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
    );
  }
}