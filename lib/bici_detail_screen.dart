import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'routes/frontend_routes.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class BiciDetailScreen extends StatefulWidget {
  final String idBici;
  const BiciDetailScreen({Key? key, required this.idBici}) : super(key: key);

  @override
  State<BiciDetailScreen> createState() => _BiciDetailScreenState();
}

class _BiciDetailScreenState extends State<BiciDetailScreen> {
  Map<String, dynamic>? bici;
  bool isLoading = true;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchBici();
  }

  Future<void> fetchBici() async {
    final url = Uri.parse(
      FrontendRoutes.build(FrontendRoutes.biciDetailById(widget.idBici)),
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        setState(() {
          bici = json.decode(decodedResponse);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.bici_detail_error_loading('${response.statusCode}'))),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.bici_detail_error_request(e.toString()))),
      );
    }
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

  Future<void> _reservarBici(String tipoBici) async {
    final token = await getAccessToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.notificar_error_token_missing)),
      );
      return;
    }

  final url = Uri.parse(
    FrontendRoutes.build(FrontendRoutes.biciReserva),
  );
    final body = {
      "estacion": int.tryParse(widget.idBici) ?? widget.idBici,
      "tipo_bicicleta": tipoBici,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.bici_reserva_ok)),
          
        );
        fetchBici();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.loc.bici_reserva_error}: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.loc.bici_reserva_error_conexion}: $e')),
      );
    }
  }

  void _showReservaModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.loc.bici_reserva_selecciona_tipo,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.directions_bike),
                    label: Text(context.loc.bici_tipo_mecanica),
                    onPressed: () {
                      Navigator.pop(context);
                      _reservarBici('mecanica');
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.electric_bike),
                    label: Text(context.loc.bici_tipo_electrica),
                    onPressed: () {
                      Navigator.pop(context);
                      _reservarBici('electrica');
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    bool valueBelow = false, // Nuevo parámetro para controlar si el valor va debajo
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? Colors.orange),
          const SizedBox(width: 10),
          Flexible(
            child: valueBelow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$label:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        softWrap: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 2.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 16),
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '$label:',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          softWrap: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 16),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (bici == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.bici_detail_title)),
        body: Center(child: Text(loc.bici_detail_unknown_address)),
      );
    }

    final estado = bici!['estado'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(bici!['name'] ?? loc.bici_detail_title),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 24.0),
        child: ListView(
          children: [
            Center(
              child: Text(
                bici!['name'] ?? loc.bici_detail_title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              icon: Icons.directions_bike,
              label: loc.bici_detail_capacity,
              value: bici!['capacity']?.toString() ?? '',
              color: Colors.orange,
            ),
            _buildInfoRow(
              icon: Icons.bolt,
              label: loc.bici_detail_is_charging_station,
              value: (bici!['is_charging_station'] ?? false)
                  ? loc.bici_detail_yes
                  : loc.bici_detail_no,
              color: Colors.orange,
            ),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              loc.bici_detail_estado,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 14 : 18,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.update,
              label: loc.bici_detail_ultima_actualizacion,
              value: formatFechaHora(estado['ultima_actualizacion_global'] ?? ''),
              color: Colors.orange,
              valueBelow: true,
            ),
            _buildInfoRow(
              icon: Icons.pedal_bike,
              label: loc.bici_detail_num_bicis_disponibles,
              value: estado['num_bicis_disponibles']?.toString() ?? '',
              color: Colors.orange,
            ),
            _buildInfoRow(
              icon: Icons.directions_bike,
              label: loc.bici_detail_num_bicis_mecanicas,
              value: estado['num_bicis_mecanicas']?.toString() ?? '',
              color: Colors.orange,
            ),
            _buildInfoRow(
              icon: Icons.electric_bike,
              label: loc.bici_detail_num_bicis_electricas,
              value: estado['num_bicis_electricas']?.toString() ?? '',
              color: Colors.orange,
            ),
            _buildInfoRow(
              icon: Icons.lock_open,
              label: loc.bici_detail_num_docks_disponibles,
              value: estado['num_docks_disponibles']?.toString() ?? '',
              color: Colors.orange,
            ),
            _buildInfoRow(
              icon: Icons.info,
              label: loc.bici_detail_estado,
              value: estado['estado'] ?? '',
              color: Colors.orange,
            ),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final lat = bici!['lat'] as double? ?? 0.0;
                        final lng = bici!['lon'] as double? ?? 0.0;
                        _openGoogleMaps(lat, lng);
                      },
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: Text(
                        loc.how_to_arrive,
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 24,
                          vertical: isSmallScreen ? 8 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showReservaModal,
                      icon: const Icon(Icons.lock, color: Colors.white),
                      label: Text(
                        loc.bici_detail_reserve,
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 24,
                          vertical: isSmallScreen ? 8 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}