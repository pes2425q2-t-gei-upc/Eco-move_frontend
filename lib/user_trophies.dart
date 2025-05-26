import 'dart:convert';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import '../l10n/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProfile {
  String firstName;
  String lastName;
  String email;
  String description;
  String language;
  String telephone;
  String username;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.description,
    required this.language,
    required this.telephone,
    required this.username,
  });
}

class UserTrophiesPage extends StatefulWidget {
  const UserTrophiesPage({super.key});

  @override
  State<UserTrophiesPage> createState() => _UserTrophiesPageState();
}

class _UserTrophiesPageState extends State<UserTrophiesPage> {
  int? _userId;
  int _puntos = 0;
  double _progreso = 0;
  Map<String, dynamic>? _siguienteTrofeo;
  List<dynamic> _trofeosConseguidos = [];
  List<dynamic> _trofeosPendientes = [];

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _token;


  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    _token = await _secureStorage.read(key: 'access');
    if (_token == null) return;

    final response = await http.get(
      Uri.parse(FrontendRoutes.build(FrontendRoutes.me)),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      setState(() {
        _userId = body['id'];
      });
      await _fetchPoints();
      await _fetchTrophies();
    } else {
      print('Error fetching user profile: ${response.statusCode}');
    }
  }


  Future<void> _fetchPoints() async {
    final response = await http.get(Uri.parse(FrontendRoutes.build(FrontendRoutes.usuariGetPunts(_userId!))),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _puntos = data['puntos'];
      });
    }
  }

  Future<void> _fetchTrophies() async {
    final response = await http.get(Uri.parse(FrontendRoutes.build(FrontendRoutes.usuariTrofeos(_userId!))),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _trofeosConseguidos = data['trofeos_conseguidos'];
        _trofeosPendientes = data['trofeos_pendientes'];
        _siguienteTrofeo = data['siguiente_trofeo'];
        _progreso = data['progreso_siguiente']?.toDouble() ?? 0;
      });
    }
  }

  Widget _buildTrophyCard(Map<String, dynamic> trofeo, {bool earned = false}) {
    final trophyName = trofeo['nombre_traducido'] ?? trofeo['nombre'];
    final trophyDesc = trofeo['descripcion_traducida'] ?? trofeo['descripcion'];
    print('trofeo val');
    print(trofeo);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: earned ? Colors.lightGreen[100] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  earned ? Icons.emoji_events : Icons.lock,
                  color: earned ? Colors.green : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    trophyName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${trofeo['puntos_necesarios']} pts',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              trophyDesc,
              style: const TextStyle(fontSize: 13),
            )
          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.loc.settings_my_trophies)),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchTrophies();
          await _fetchPoints();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${context.loc.settings_current_points}: $_puntos', 
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (_siguienteTrofeo != null) ...[
              Text(
                '${context.loc.settings_next_trophy}: ${_siguienteTrofeo!['nombre']} (${_siguienteTrofeo!['puntos_necesarios']} pts)',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _progreso / 100,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              context.loc.settings_trophies_earned, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            ..._trofeosConseguidos.map((t) => _buildTrophyCard(t['trofeo'], earned: true)).toList(),
            const SizedBox(height: 24),
            Text(
              context.loc.settings_pending_trophies, 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            ..._trofeosPendientes.map((t) => _buildTrophyCard(t)).toList(),
          ],
        ),
      ),
    );
  }
}
