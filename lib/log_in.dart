import 'dart:convert';
import 'package:eco_move_frontend/config.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'sign-in.dart';
import 'main.dart'; // Import main.dart to access MyHomePage
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:eco_move_frontend/routes/frontend_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true; // Add this to control password visibility

  // Modify the initState() method in the _LoginScreenState class (paste-3.txt)

  @override
  void initState() {
    super.initState();
    // Check for existing token when the login screen initializes
    checkExistingToken();
  }

  // Add this new method to _LoginScreenState class

  Future<void> checkExistingToken() async {
    // Get the access token from secure storage
    String? accessToken = await getAccessToken();
    print(accessToken);
    if (accessToken != null && accessToken.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MyHomePage(title: 'ECO-MOVE')),
      );
    }
  }

  // Add this method to verify token validity (recommended)

  Future<bool> validateToken(String token) async {
    try {
      // You can make a request to your backend to verify the token
      final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.me));

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      // If response is successful, token is valid
      return response.statusCode == 200;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

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
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.login));
    print('la url del get token de log in es ${url}');
    final Map<String, dynamic> data = {
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    print(data);
    print(url);

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

        // Navigate to MyHomePage after successful login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MyHomePage(title: 'ECO-MOVE'),
          ),
        );
      } else if (response.statusCode == 401) {
        String? r = await getRefreshToken();
        getTokenRefresh(r!);
      } else {
        print('Error al fer login: ${response.statusCode} - ${response.body}');
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de inicio de sesión: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      // Show error message to user
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    }
  }

  Future<void> getTokenRefresh(String refresh) async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.refreshToken));

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

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MyHomePage(title: 'ECO-MOVE'),
          ),
        );
      } else {
        print(
          'Failed to create reservation: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<bool> signInWithGoogle(BuildContext context) async {
    try {
      // Initialize Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Attempt to sign in
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // If user cancels the sign-in process
      if (googleUser == null) {
        return false;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Get the access token
      final String? accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        throw Exception("Failed to obtain access token");
      }

      // Send the token to your backend
      final response = await http.post(
        Uri.parse('${AppConfig.apiBase}/auth/social/google/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'access_token': accessToken,
        }),
      );

      // Check if the request was successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response from your backend
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print(responseData);
        saveAccessToken(responseData['access'], responseData['refresh']);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(title: 'ECO-MOVE'),
          ),
        );


        return true;
      } else {
        // Handle the error
        print('Failed to authenticate with backend: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }

    } catch (error) {
      print('Error during Google sign in: $error');
      return false;
    }
  }



  Future<void> _getInfo(String token) async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.me));

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
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon),
          // Add suffix icon for password field
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                  : null,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        obscureText:
            isPassword &&
            _obscurePassword, // Use the visibility state for password field
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
                const SizedBox(height: 32),
                _buildTextField('Email', _emailController, Icons.person),
                _buildTextField(
                  'Contraseña',
                  _passwordController,
                  Icons.lock,
                  isPassword: true, // Set this field as a password field
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
                const SizedBox(height: 12),
                const SizedBox(height: 12),
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
                        signInWithGoogle(context);
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
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'No tienes cuenta?',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Crear cuenta',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
