import 'dart:convert';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:share_plus/share_plus.dart';
import 'rate-charger.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'calculate_price.dart';
import 'book_charger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:eco_move_frontend/list-ratings.dart';
import 'notificar_error_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: EstacionScreen(idStation: '46109488'));
  }
}

class EstacionScreen extends StatefulWidget {
  final String idStation;

  const EstacionScreen({required this.idStation, super.key});

  @override
  State<EstacionScreen> createState() =>
      _EstacionScreenState(idStation: idStation);
}

class _EstacionScreenState extends State<EstacionScreen> {
  final String idStation;
  Map<String, dynamic> stationData = {};
  bool isLoading = true;

  _EstacionScreenState({required this.idStation});

  Future<void> _fetchStations() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
      FrontendRoutes.build(
        FrontendRoutes.estacion(idStation),
      ),
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        Map<String, dynamic> data = jsonDecode(decodedResponse);

        setState(() {
          stationData = data;
          isLoading = false;
        });
      } else {
        print('Error: Received status code ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error during HTTP request: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchStations();
  }

  Color _getStatusColor() {
    if (stationData['fuera_de_servicio'] == true) return Colors.red;
    if (stationData['nplaces'] != null && int.tryParse(stationData['nplaces'])! > 0) {
      return Colors.green;
    }
    return Colors.orange;
  }

  String _getStatusText() {
    if (stationData['fuera_de_servicio'] == true) {
      return context.loc.out_of_service ?? 'Out of Service';
    }
    if (stationData['nplaces'] != null && int.tryParse(stationData['nplaces'])! > 0) {
      return context.loc.disponible;
    }
    return context.loc.busy;
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();
    final isOutOfService = stationData['fuera_de_servicio'] == true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOutOfService ? Icons.error_outline :
                    (statusColor == Colors.green ? Icons.check_circle : Icons.schedule),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      if (isOutOfService &&
                          stationData['motivo_fuera_servicio'] != null &&
                          stationData['motivo_fuera_servicio'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          stationData['motivo_fuera_servicio'].toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (isOutOfService) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.loc.station_no_actions_available ??
                            'Limited actions available while station is out of service.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  context.loc.station_info,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              icon: Icons.location_on,
              label: context.loc.station_city,
              value: stationData['ciutat'] ?? 'No disponible',
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              icon: Icons.power,
              label: context.loc.station_power,
              value: stationData['potencia'] != null
                  ? '${stationData['potencia']} kW'
                  : 'N/A',
            ),
            const SizedBox(height: 16),

            // Plug types section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.electrical_services, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${context.loc.station_plug_type}:',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (stationData['tipus_carregador'] as List<dynamic>? ?? [])
                  .expand((tipo) => (tipo ?? '').split('+'))
                  .map<Widget>((tipo) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  tipo.trim(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.white : backgroundColor,
          foregroundColor: isSecondary ? backgroundColor : Colors.white,
          elevation: isSecondary ? 1 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSecondary ? BorderSide(color: backgroundColor) : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          final mapUrl = 'https://www.google.com/maps/dir/?api=1&destination=${stationData['lat']},${stationData['lng']}';
          final shareMessage = '${context.loc.station_share_message_1}: ${stationData['direccio'] ?? 'Cargando...'}\n${context.loc.station_share_message_2}: $mapUrl';
          await Share.shareWithResult(shareMessage);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black87,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.share, size: 20),
            const SizedBox(width: 12),
            Text(
              context.loc.station_share_station,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfService = stationData['fuera_de_servicio'] == true;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isLoading
              ? 'Cargando...'
              : '${context.loc.station} ${stationData['direccio'] ?? 'Desconocida'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando información de la estación...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchStations,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${context.loc.station} ${stationData['direccio'] ?? 'Desconocida'}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff4a7c59),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12,),
              _buildStatusCard(),
              const SizedBox(height: 20),

              // Info Card
              _buildInfoCard(),
              const SizedBox(height: 24),

              // Actions Section
              if (isOutOfService) ...[
                // Limited actions for out of service
                _buildActionButton(
                  icon: Icons.error_outline,
                  text: context.loc.station_report_error,
                  backgroundColor: Colors.red,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NotificarErrorScreen(idStation: idStation),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildShareButton(),
              ] else ...[
                // Full actions for working stations
                Text(
                  context.loc.available_actions,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),

                _buildActionButton(
                  icon: Icons.navigation,
                  text: context.loc.how_to_arrive,
                  backgroundColor: Colors.green,
                  onPressed: () => _openGoogleMaps(stationData['lat'], stationData['lng']),
                ),
                const SizedBox(height: 12),

                _buildActionButton(
                  icon: Icons.calculate,
                  text: context.loc.station_calculate_price,
                  backgroundColor: Colors.blue,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChargeCalculatorScreen(
                          tipoCarga: stationData['tipus_velocitat'],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildActionButton(
                  icon: Icons.calendar_today,
                  text: context.loc.station_reserve,
                  backgroundColor: Colors.purple,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BookChargerScreen(idStation: idStation),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                Text(
                  context.loc.ratings,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),

                _buildActionButton(
                  icon: Icons.star_outline,
                  text: context.loc.station_view_reviews,
                  backgroundColor: Colors.orange,
                  isSecondary: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ListRatingsScreen(idStation: idStation),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildActionButton(
                  icon: Icons.rate_review,
                  text: context.loc.station_give_review,
                  backgroundColor: Colors.orange,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RatingScreen(idStation: idStation),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                Text(
                  context.loc.other_options,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),

                _buildActionButton(
                  icon: Icons.report_problem,
                  text: context.loc.station_report_error,
                  backgroundColor: Colors.red,
                  isSecondary: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NotificarErrorScreen(idStation: idStation),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildShareButton(),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps(
      double destinationLatitude,
      double destinationLongitude,
      ) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$destinationLatitude,$destinationLongitude';
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }
}