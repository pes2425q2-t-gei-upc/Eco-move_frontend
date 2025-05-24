import 'package:flutter/material.dart';
import 'EmergencyService.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'EmergenciaDetails.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.loc.alert_emergency_points)),
      body: FutureBuilder<List<EmergencyPoint>>(
        future: _emergencyPointsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains('404')) {
              return Center(child: Text('Error 404: ${context.loc.alert_endpoint_not_found}'));
            }
            return Center(child: Text('Error: $error'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(context.loc.alert_no_emergency_points_found));
          } else {
            final points = snapshot.data!;
            print('aqui points val ${points}');
            return ListView.builder(
              itemCount: points.length,
              itemBuilder: (context, index) {
                final point = points[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(point.title),
                    subtitle: Text(point.description),
                    trailing: Text(point.timestamp),
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
            );
          }
        },
      ),
    );
  }
}
