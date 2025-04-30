import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perfil usuario',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
        useMaterial3: true,
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

  String? selectedLanguage;
  bool _isPass1Visible = false;
  bool _isPass2Visible = false;


  @override
  void initState() {
    super.initState();
    _initControllers();
    //iniUser();
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
      appBar: AppBar(
        title: const Text('Registro usuario'),
      ),
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
          const SizedBox(height: 24),
          _buildTextField('Nombre', firstNameController, Icons.person),
          _buildTextField('Apellido', lastNameController, Icons.person),
          _buildTextField('Usuario',  usernameController, Icons.person),
          _buildTextField('Email', emailController, Icons.email),
          _buildTextField('Teléfono (opcional)', telephoneController, Icons.phone),
          _buildPasswordField('Contraseña', pass1Controller, isPass1Visible: _isPass1Visible, toggleVisibility: () {
            setState(() {
              _isPass1Visible = !_isPass1Visible;
            });
          }),
          _buildPasswordField('Repita su contraseña', pass2Controller, isPass1Visible: _isPass2Visible, toggleVisibility: () {
            setState(() {
              _isPass2Visible = !_isPass2Visible;
            });
          }),
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
        decoration: const InputDecoration(
          labelText: 'Idioma',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.language),
        ),
        value: selectedLanguage,
        items: const [
          DropdownMenuItem(
            value: 'Català',
            child: Text('Català'),
          ),
          DropdownMenuItem(
            value: 'Castellano',
            child: Text('Castellano'),
          ),
          DropdownMenuItem(
            value: 'English',
            child: Text('English'),
          ),
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
      IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}
      ) {
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
      TextEditingController controller,
      {required bool isPass1Visible, required Function toggleVisibility}
      ) {
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
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
        child: const Text('Registrarme'),
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
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  void _validatePasswords() {
    if (pass1Controller.text.length < 8) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('La contraseña debe tener al menos 8 caracteres.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
    else if (pass1Controller.text != pass2Controller.text) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Las contraseñas no coinciden. Por favor, inténtelo de nuevo.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      createUser();
    }
  }

  Future<void> createUser() async {
    final url = Uri.parse('http://10.0.2.2:8000/register/');

    final Map<String, dynamic> data = {
      'first_name': firstNameController.text,
      'last_name': lastNameController.text,
      'email': emailController.text.toLowerCase(),
      'username': usernameController.text,
      'idioma': languageController.text,
      'telefon':telephoneController.text,
      'descripcio':descriptionController.text,
      'password': pass1Controller.text,
      'password2': pass2Controller.text,
    };

    print(data);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        print('Reservation created successfully');
      } else {
        _alert(response.body);
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}