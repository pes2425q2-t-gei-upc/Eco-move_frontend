import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'main.dart';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: context.loc.sign_in_user_profile,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.green.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade600, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ),
      home: const UserProfilePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  // Controllers for edit form
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController descriptionController;
  late TextEditingController languageController;
  late TextEditingController telephoneController;
  late TextEditingController usernameController;
  late TextEditingController pass1Controller;
  late TextEditingController pass2Controller;

  String selectedLanguage = 'Castellano';
  bool _isPass1Visible = false;
  bool _isPass2Visible = false;

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> saveAccessToken(String access, String refresh) async {
    await _secureStorage.write(key: 'access', value: access);
    await _secureStorage.write(key: 'refresh', value: refresh);
    print(access);
  }

  @override
  void initState() {
    super.initState();
    _initControllers();
    //iniUser();
  }

  Future<void> getToken() async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.token));
    print('la url del get token del login es ${url}');
    final Map<String, dynamic> data = {
      'email': emailController.text,
      'password': pass1Controller.text,
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
        print('Registre correcte');
        print('retorna: ${response.body}');
        saveAccessToken(resp['access'], resp['refresh']);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MyHomePage(title: 'ECO-MOVE'),
          ),
        );
      } else {
        print('Error al fer login: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de inicio de sesión: ${response.body}'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _initControllers() {
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    descriptionController = TextEditingController();
    languageController = TextEditingController();
    telephoneController = TextEditingController();
    usernameController = TextEditingController();
    pass1Controller = TextEditingController();
    pass2Controller = TextEditingController();
    languageController.text = selectedLanguage;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    descriptionController.dispose();
    languageController.dispose();
    telephoneController.dispose();
    usernameController.dispose();
    pass1Controller.dispose();
    pass2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          context.loc.sign_in_register_user,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4CAF50),
                const Color(0xFF66BB6A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Personal Information', Icons.person),
          const SizedBox(height: 16),
          _buildTextField(
            context.loc.sign_in_first_name,
            firstNameController,
            Icons.person_outline,
          ),
          _buildTextField(
            context.loc.sign_in_last_name,
            lastNameController,
            Icons.person_outline,
          ),
          _buildTextField(
            context.loc.sign_in_username,
            usernameController,
            Icons.alternate_email,
          ),

          const SizedBox(height: 24),

          // Contact Information Section
          _buildSectionHeader('Contact Information', Icons.contact_mail),
          const SizedBox(height: 16),
          _buildTextField(
            context.loc.login_email,
            emailController,
            Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          _buildTextField(
            context.loc.sign_in_phone_optional,
            telephoneController,
            Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 24),

          // Security Section
          _buildSectionHeader('Security', Icons.security),
          const SizedBox(height: 16),
          _buildPasswordField(
            context.loc.login_password,
            pass1Controller,
            isPass1Visible: _isPass1Visible,
            toggleVisibility: () {
              setState(() {
                _isPass1Visible = !_isPass1Visible;
              });
            },
          ),
          _buildPasswordField(
            context.loc.sign_in_repeat_password,
            pass2Controller,
            isPass1Visible: _isPass2Visible,
            toggleVisibility: () {
              setState(() {
                _isPass2Visible = !_isPass2Visible;
              });
            },
          ),

          const SizedBox(height: 24),

          // Preferences Section
          _buildSectionHeader('Preferences', Icons.settings),
          const SizedBox(height: 16),
          _buildLanguageDropdown(),

          const SizedBox(height: 32),
          _registerButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.green.shade600,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: context.loc.sign_in_language,
          labelStyle: TextStyle(color: Colors.green.shade700),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(Icons.language, color: Colors.green.shade600),
        ),
        value: selectedLanguage,
        dropdownColor: Colors.green.shade50,
        items: const [
          DropdownMenuItem(value: 'Catala', child: Text('Català')),
          DropdownMenuItem(value: 'Castellano', child: Text('Castellano')),
          DropdownMenuItem(value: 'English', child: Text('English')),
        ],
        onChanged: (value) {
          setState(() {
            selectedLanguage = value!;
            languageController.text = value;
          });
        },
      ),
    );
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
          labelText: label,
          labelStyle: TextStyle(color: Colors.green.shade700),
          prefixIcon: Icon(icon, color: Colors.green.shade600),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
      ),
    );
  }

  Widget _buildPasswordField(
      String label,
      TextEditingController controller, {
        required bool isPass1Visible,
        required Function toggleVisibility,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        obscureText: !isPass1Visible,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.green.shade700),
          prefixIcon: Icon(Icons.lock_outline, color: Colors.green.shade600),
          suffixIcon: IconButton(
            icon: Icon(
              isPass1Visible ? Icons.visibility_off : Icons.visibility,
              color: Colors.green.shade600,
            ),
            onPressed: () => toggleVisibility(),
          ),
        ),
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
      ),
    );
  }

  Widget _registerButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50),
            const Color(0xFF66BB6A),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade300,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          _validatePasswords();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.loc.sign_in_register_button,
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

  Future<void> _alert(String r) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text('Error'),
            ],
          ),
          content: Text(r),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green.shade600,
              ),
              child: Text(context.loc.sign_in_ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _validatePasswords() async {
    if (pass1Controller.text.length < 8) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_outlined, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text('Password Requirements'),
              ],
            ),
            content: Text(context.loc.sign_in_password_too_short),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green.shade600,
                ),
                child: Text(context.loc.sign_in_ok),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else if (pass1Controller.text != pass2Controller.text) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_outlined, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text('Password Mismatch'),
              ],
            ),
            content: Text(context.loc.sign_in_passwords_do_not_match),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green.shade600,
                ),
                child: Text(context.loc.sign_in_ok),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      await createUser();
      await getToken();
    }
  }

  Future<void> createUser() async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.register));
    print(url);
    final Map<String, dynamic> data = {
      'first_name': firstNameController.text,
      'last_name': lastNameController.text,
      'email': emailController.text.toLowerCase(),
      'username': usernameController.text,
      'idioma': languageController.text,
      'telefon': telephoneController.text,
      'descripcio': descriptionController.text,
      'password': pass1Controller.text,
      'password2': pass2Controller.text,
    };

    print(data);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        print('Reservation created successfully');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MyHomePage(title: 'ECO-MOVE'),
          ),
        );
      } else {
        _alert(response.body);
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}