import 'package:flutter/material.dart';
import 'EmergencyService.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'EmergenciaDetails.dart';
import 'package:intl/intl.dart';

class EmergencyScreen extends StatefulWidget {
  final double userLat;
  final double userLng;

  const EmergencyScreen({Key? key, required this.userLat, required this.userLng}) : super(key: key);

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  late Future<List<EmergencyPoint>> _emergencyPointsFuture;

  @override
  void initState() {
    super.initState();
    _emergencyPointsFuture = EmergencyService().fetchEmergencyPoints(widget.userLat, widget.userLng);
  }

  String formatFechaHora(String fechaIso) {
    final date = DateTime.parse(fechaIso).toLocal();
    final fecha = DateFormat('dd/MM/yyyy').format(date);
    final hora = DateFormat('HH:mm').format(date);
    return '$fecha $hora h';
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo neutro
      appBar: AppBar(
        title: Text(loc.alert_emergency_points),
        backgroundColor: const Color(0xFFFF6F61), // Rojo pastel/suave
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: FutureBuilder<List<EmergencyPoint>>(
        future: _emergencyPointsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains('404')) {
              return Center(child: Text('Error 404: ${loc.alert_endpoint_not_found}'));
            }
            return Center(child: Text('Error: $error'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(loc.alert_no_emergency_points_found));
          } else {
            final points = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    loc.alert_emergency_points_subtitle,
                      style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 0, 0, 0), // Más negro y visible
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: points.length,
                    itemBuilder: (context, index) {
                      final point = points[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: Icon(Icons.warning, color: Colors.redAccent),
                          ),
                          title: Text(
                            point.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(point.description),
                              const SizedBox(height: 4),
                              Text(
                                formatFechaHora(point.timestamp),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EmergenciaDetails(
                                  title: point.title,
                                  description: point.description,
                                  lat: point.lat,
                                  lng: point.lng,
                                  timestamp: point.timestamp,
                                  sender: point.sender,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}