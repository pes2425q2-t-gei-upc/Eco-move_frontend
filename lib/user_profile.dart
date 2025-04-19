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
    dni: '47114817Z',
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
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _toggleEditMode();
                editUser();
              } else {
                _toggleEditMode();
              }
            },
          ),
        ],
      ),
      body: isEditing ? _buildEditForm() : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildInfoSection('Nombre', userProfile.firstName, Icons.person),
          _buildInfoSection('Apellido', userProfile.lastName, Icons.person),
          _buildInfoSection('Usuario', userProfile.username, Icons.person),
          _buildInfoSection('Email', userProfile.email, Icons.email),
          _buildInfoSection('Teléfono', userProfile.telephone, Icons.phone),
          _buildInfoSection('Idioma', userProfile.language, Icons.language),
          const SizedBox(height: 16),
          _buildDescriptionSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundColor: Color(0xE278A879),
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

  Widget _buildInfoSection(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Color(0xE278A879)),
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
                value,
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
          userProfile.description,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          /*const Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 80, color: Colors.white),
            ),
          ),*/
          const SizedBox(height: 24),
          _buildTextField('Nombre', firstNameController, Icons.person),
          _buildTextField('Apellido', lastNameController, Icons.person),
          _buildTextField('Usuario', usernameController, Icons.person),
          _buildTextField('Email', emailController, Icons.email, keyboardType: TextInputType.emailAddress),
          _buildTextField('Telefono', telephoneController, Icons.phone, keyboardType: TextInputType.phone),
          _buildTextField('Idioma', languageController, Icons.language),
          _buildTextField('Descripcion', descriptionController, Icons.description, maxLines: 4),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _toggleEditMode();
              editUser();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xE278A879),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Guardar cambios'),
          ),
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

  Future<void> editUser() async {
    print('Starting editUser function...');
    final url = Uri.parse('http://10.0.2.2:8000/api_punts_carrega/usuari/1/');

    final Map<String, dynamic> data = {
      'first_name': userProfile.firstName,
      'last_name': userProfile.lastName,
      'email': userProfile.email,
      'username':userProfile.username,
      'dni': userProfile.dni,
      'idioma':userProfile.language,
      'telefon':userProfile.telephone,
      'descripcio':userProfile.description,
      'is_admin': false,
    };

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        print('Reservation created successfully');
      } else {
        print('Failed to create reservation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> iniUser() async {
    final url = Uri.parse('http://10.0.2.2:8000/api_punts_carrega/usuari/');

    final Map<String, dynamic> data = {
      'first_name': userProfile.firstName,
      'last_name': userProfile.lastName,
      'email': userProfile.email,
      'username':userProfile.username,
      'dni': userProfile.dni,
      'idioma':userProfile.language,
      'telefon':userProfile.telephone,
      'descripcio':userProfile.description,
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