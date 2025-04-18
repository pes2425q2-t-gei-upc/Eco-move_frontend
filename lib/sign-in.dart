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

class UserProfile {
  String firstName;
  String lastName;
  String email;
  String description;
  String language;
  String telephone;
  String dni;
  String username;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.description,
    required this.language,
    required this.telephone,
    required this.dni,
    required this.username,
  });
}

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool isEditing = false;

  final UserProfile userProfile = UserProfile(
    firstName: 'Laura',
    lastName: 'van Dinteren',
    email: 'laura.van.dinteren@estudiantat.upc.edu',
    description: 'nose que posar aqui pero vale',
    language: 'Català',
    telephone: '653972950',
    dni: '471148122',
    username: 'lauravandi',
  );

  // Controllers for edit form
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController descriptionController;
  late TextEditingController languageController;
  late TextEditingController telephoneController;
  late TextEditingController usernameController;

  @override
  void initState() {
    super.initState();
    _initControllers();
    //iniUser();
  }

  void _initControllers() {
    firstNameController = TextEditingController(text: userProfile.firstName);
    lastNameController = TextEditingController(text: userProfile.lastName);
    emailController = TextEditingController(text: userProfile.email);
    descriptionController = TextEditingController(text: userProfile.description);
    languageController = TextEditingController(text: userProfile.language);
    telephoneController = TextEditingController(text: userProfile.telephone);
    usernameController = TextEditingController(text: userProfile.username);
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
    super.dispose();
  }

  void _toggleEditMode() {
    if (isEditing) {
      // Save the data
      setState(() {
        userProfile.firstName = firstNameController.text;
        userProfile.lastName = lastNameController.text;
        userProfile.email = emailController.text;
        userProfile.description = descriptionController.text;
        userProfile.language = languageController.text;
        userProfile.telephone = telephoneController.text;
        userProfile.username = usernameController.text;
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } else {
      // Enter edit mode
      setState(() {
        _initControllers();
        isEditing = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil usuario'),
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
          _buildTextField('Email', emailController, Icons.email),
          _buildTextField('Usuario',  usernameController, Icons.email),
          _buildTextField('Teléfono', telephoneController, Icons.phone),
          _buildTextField('Idioma',languageController, Icons.language),
          const SizedBox(height: 16),
          _buildDescriptionSection(),

        ],
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
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }


  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            '${userProfile.firstName} ${userProfile.lastName}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Descripción',
          style: const TextStyle(fontSize: 16),
        ),
        TextButton(
            onPressed: () {
              createUser();
            },
            child: Text('Registrarme'))
      ],
    );
  }

  Future<void> createUser() async {
    final url = Uri.parse('http://10.0.2.2:8000/api_punts_carrega/usuari/');

    final Map<String, dynamic> data = {
      'first_name': firstNameController.text,
      'last_name': lastNameController.text,
      'email': emailController.text,
      'username': usernameController.text,
      'dni': '1122332222',
      'idioma': languageController.text,
      'telefon':telephoneController.text,
      'descripcio':descriptionController.text,
      'is_admin': false,
    };

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
        print('Failed to create reservation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}