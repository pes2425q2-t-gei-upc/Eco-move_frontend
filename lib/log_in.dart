import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';

void main() {
  runApp(
    const MaterialApp(home: LoginScreen(), debugShowCheckedModeBanner: false),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> saveAccessToken(String access, String refresh) async {
    await _secureStorage.write(key: 'access', value: access);
    await _secureStorage.write(key: 'refresh', value: refresh);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> getToken() async {
    final url = Uri.parse('http://10.0.2.2:8000/token/');

    final Map<String, dynamic> data = {
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    print(data);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      final Map<String, dynamic> resp = json.decode(response.body);

      if (response.statusCode == 200) {
        print('Log in correcte');
        print('retorna: ${response.body}');
        saveAccessToken(resp['access'], resp['refresh']);
        _getInfo(resp['access']);
      } else if (response.statusCode == 401) {
        String? r = await getRefreshToken();
        getTokenRefresh(r!);
      } else {
        print('Error al fer login: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> getTokenRefresh(String refresh) async {
    final url = Uri.parse('http://10.0.2.2:8000/token/refresh/');

    final Map<String, dynamic> data = {'refresh': refresh};

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        print('retorna refresh: ${response.body}');
        final Map<String, dynamic> resp = json.decode(response.body);
        _getInfo(resp['access']);
      } else {
        print(
          'Failed to create reservation: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _getInfo(String token) async {
    final url = Uri.parse('http://10.0.2.2:8000/me/');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        print('Les dades són: $data');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user info')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        obscureText: label == 'Password', // Enable password hiding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  context.loc.login_title,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                _buildTextField(
                  context.loc.login_email,
                  _emailController,
                  Icons.person,
                ),
                _buildTextField(
                  context.loc.login_password,
                  _passwordController,
                  Icons.lock,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    getToken();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    context.loc.login_title,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(context.loc.login_or),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google sign in button
                    ElevatedButton.icon(
                      onPressed: () {
                        // Implement Google sign in
                      },
                      icon: const FaIcon(
                        FontAwesomeIcons.google,
                        size: 24,
                        color: Colors.black,
                      ),
                      label: const Text('Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // GitHub sign in button
                    ElevatedButton.icon(
                      onPressed: () {
                        // Implement GitHub sign in
                      },
                      icon: const FaIcon(
                        FontAwesomeIcons.github,
                        size: 24,
                        color: Colors.white,
                      ),
                      label: const Text('GitHub'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
