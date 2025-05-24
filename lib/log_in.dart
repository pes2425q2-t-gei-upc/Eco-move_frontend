import 'dart:convert';
import 'package:eco_move_frontend/config.dart';
import 'package:eco_move_frontend/l10n/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'sign-in.dart';
import 'main.dart'; // Import main.dart to access MyHomePage
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  bool _obscurePassword = true;
  bool _isLoading = false;
  static String token = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _initialize();
  }

  Future<void> _initialize() async {
    checkExistingToken();
    token = (await getAccessToken()) ?? '';
  }

  Future<void> checkExistingToken() async {
    String? accessToken = await getAccessToken();
    print(accessToken);
    if (accessToken != null && accessToken.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MyHomePage(title: 'ECO-MOVE')),
      );
    }
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  Future<bool> validateToken(String token) async {
    try {
      final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.me));
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  Future<void> saveAccessToken(String access, String refresh) async {
    await _secureStorage.write(key: 'access', value: access);
    await _secureStorage.write(key: 'refresh', value: refresh);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> getToken() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.token));
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
        await _getInfo(resp['access']);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MyHomePage(title: 'ECO-MOVE'),
          ),
        );
      } else if (response.statusCode == 401) {
        String? r = await getRefreshToken();
        if (r != null) {
          getTokenRefresh(r);
        }
      } else {
        print('Error al fer login: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de inicio de sesión: ${response.body}'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> getTokenRefresh(String refresh) async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.tokenRefresh));
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
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
          'https://www.googleapis.com/auth/calendar',
          'https://www.googleapis.com/auth/calendar.events'
        ],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        throw Exception("Failed to obtain access token");
      }

      final response = await http.post(
        Uri.parse(FrontendRoutes.build(FrontendRoutes.googleSignin)),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'access_token': accessToken,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
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
        print('Failed to authenticate with backend: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (error) {
      print('Error during Google sign in: $error');
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
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

        final String idioma = data['idioma'] ?? 'English';

        String langCode;
        switch (idioma) {
          case 'Catala':
            langCode = 'ca';
            break;
          case 'Castellano':
            langCode = 'es';
            break;
          case 'English':
          default:
            langCode = 'en';
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('Language', langCode);

        Provider.of<LocaleProvider>(context, listen: false)
            .setLocale(Locale(langCode));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user info')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
        bool isPassword = false,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && _obscurePassword,
        style: TextStyle(
          fontSize: 16,
          color: Colors.green.shade800,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.green.shade600,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.green.shade600,
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.green.shade600,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50),
            const Color(0xFF66BB6A),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade300.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () async {
          await getToken();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.login,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              context.loc.login_title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () {
          signInWithGoogle(context);
        },
        icon: const FaIcon(
          FontAwesomeIcons.google,
          size: 20,
          color: Colors.red,
        ),
        label: const Text(
          'Continue with Google',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade300, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add,
              color: Colors.green.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              context.loc.login_create_account,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and Welcome Section
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade100.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.eco,
                                size: 30,
                                color: Colors.green.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'ECO-MOVE',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Welcome back to sustainable mobility',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Login Form
                      _buildTextField(
                        context.loc.login_email,
                        _emailController,
                        Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      _buildTextField(
                        context.loc.login_password,
                        _passwordController,
                        Icons.lock_outline,
                        isPassword: true,
                      ),

                      const SizedBox(height: 15),

                      // Login Button
                      _buildLoginButton(),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade400,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              context.loc.login_or,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade400,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Google Sign In Button
                      _buildGoogleSignInButton(),

                      const SizedBox(width: 16),

                      const SizedBox(height: 40),

                      // No Account Text
                      Center(
                        child: Text(
                          context.loc.login_no_account,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Create Account Button
                      _buildCreateAccountButton(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}