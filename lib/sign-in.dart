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
      theme: ThemeData(primarySwatch: Colors.lightGreen, useMaterial3: true),
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

  String? selectedLanguage;
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
      appBar: AppBar(title: Text(context.loc.sign_in_register_user)),
      body: _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _buildProfileHeader(),
          SizedBox(height: 24),
          _buildTextField(
            context.loc.sign_in_first_name,
            firstNameController,
            Icons.person,
          ),
          _buildTextField(
            context.loc.sign_in_last_name,
            lastNameController,
            Icons.person,
          ),
          _buildTextField(
            context.loc.sign_in_username,
            usernameController,
            Icons.person,
          ),
          _buildTextField(
            context.loc.login_email,
            emailController,
            Icons.email,
          ),
          _buildTextField(
            context.loc.sign_in_phone_optional,
            telephoneController,
            Icons.phone,
          ),
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
          _buildLanguageDropdown(),
          const SizedBox(height: 16),
          _registerButton(),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: context.loc.sign_in_language,
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.language),
        ),
        value: selectedLanguage,
        items: const [
          DropdownMenuItem(value: 'Catala', child: Text('Catala')),
          DropdownMenuItem(value: 'Castellano', child: Text('Castellano')),
          DropdownMenuItem(value: 'English', child: Text('English')),
        ],
        onChanged: (value) {
          setState(() {
            selectedLanguage = value;
            languageController.text = value!;
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
          hintText: label,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
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
          hintText: label,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.password),
          suffixIcon: IconButton(
            icon: Icon(
              isPass1Visible ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () => toggleVisibility(),
          ),
          border: const OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(title, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _registerButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          _validatePasswords();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xE278A879),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
        child: Text(context.loc.sign_in_register_button),
      ),
    );
  }

  Future<void> _alert(String r) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(r),
          actions: <Widget>[
            TextButton(
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
            title: const Text('Error'),
            content: Text(context.loc.sign_in_password_too_short),
            actions: <Widget>[
              TextButton(
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
            title: const Text('Error'),
            content: Text(context.loc.sign_in_passwords_do_not_match),
            actions: <Widget>[
              TextButton(
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
