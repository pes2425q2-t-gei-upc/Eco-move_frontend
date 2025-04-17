import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Profile',
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
  String name;
  String email;
  String description;
  String language;
  String telephone;

  UserProfile({
    required this.name,
    required this.email,
    required this.description,
    required this.language,
    required this.telephone,
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
    name: 'John Doe',
    email: 'john.doe@example.com',
    description: 'Flutter developer with 3 years of experience. Passionate about building beautiful and functional mobile applications.',
    language: 'English',
    telephone: '+1 123-456-7890',
  );

  // Controllers for edit form
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController descriptionController;
  late TextEditingController languageController;
  late TextEditingController telephoneController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    nameController = TextEditingController(text: userProfile.name);
    emailController = TextEditingController(text: userProfile.email);
    descriptionController = TextEditingController(text: userProfile.description);
    languageController = TextEditingController(text: userProfile.language);
    telephoneController = TextEditingController(text: userProfile.telephone);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    descriptionController.dispose();
    languageController.dispose();
    telephoneController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    if (isEditing) {
      // Save the data
      setState(() {
        userProfile.name = nameController.text;
        userProfile.email = emailController.text;
        userProfile.description = descriptionController.text;
        userProfile.language = languageController.text;
        userProfile.telephone = telephoneController.text;
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
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
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: _toggleEditMode,
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
          _buildInfoSection('Email', userProfile.email, Icons.email),
          _buildInfoSection('Phone', userProfile.telephone, Icons.phone),
          _buildInfoSection('Language', userProfile.language, Icons.language),
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
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            userProfile.name,
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
          const Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 80, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField('Name', nameController, Icons.person),
          _buildTextField('Email', emailController, Icons.email, keyboardType: TextInputType.emailAddress),
          _buildTextField('Phone', telephoneController, Icons.phone, keyboardType: TextInputType.phone),
          _buildTextField('Language', languageController, Icons.language),
          _buildTextField('About', descriptionController, Icons.description, maxLines: 4),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _toggleEditMode,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Save Profile'),
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
}