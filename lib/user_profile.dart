import 'dart:convert';
import 'dart:io';
import 'package:eco_move_frontend/l10n/locale_provider.dart';
import 'package:eco_move_frontend/log_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

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
  String username;
  String? photoUrl;  // Added photoUrl field

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.description,
    required this.language,
    required this.telephone,
    required this.username,
    this.photoUrl,  // Optional photo URL
  });
}

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool isEditing = false;
  String? token = '';
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final ImagePicker _imagePicker = ImagePicker();

  late UserProfile userProfile;
  bool isLoading = true;
  int id = -1;
  File? _selectedImage;

  // List of available languages
  final List<String> languages = ['Catala', 'Castellano', 'English'];

  // Controllers for edit form
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController descriptionController;
  late TextEditingController telephoneController;
  late TextEditingController usernameController;

  // Selected language in dropdown
  late String selectedLanguage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  void _initControllers() {
    firstNameController = TextEditingController(text: userProfile.firstName);
    lastNameController = TextEditingController(text: userProfile.lastName);
    emailController = TextEditingController(text: userProfile.email);
    descriptionController = TextEditingController(text: userProfile.description);
    telephoneController = TextEditingController(text: userProfile.telephone);
    usernameController = TextEditingController(text: userProfile.username);

    // Initialize selected language
    selectedLanguage = userProfile.language;

    // Default to 'Catala' if the current language is not in our list
    if (!languages.contains(selectedLanguage)) {
      selectedLanguage = 'Catala';
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    descriptionController.dispose();
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
        userProfile.language = selectedLanguage;
        userProfile.telephone = telephoneController.text;
        userProfile.username = usernameController.text;
        isEditing = false;
      });

      // Change the frontend language
      Provider.of<LocaleProvider>(context, listen: false)
        .setLocale(_mapToLocale(selectedLanguage));

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

  Locale _mapToLocale(String language) {
    switch (language.toLowerCase()) {
      case 'català':
      case 'catala':
        return const Locale('ca');
      case 'castellano':
        return const Locale('es');
      case 'english':
      default:
        return const Locale('en');
    }
  }


  Future<void> _initialize() async {
    token = await getAccessToken();
    print(token);
    final success = await _getMyInfo();

    if (!success) {
      setState(() => isLoading = false);
      return;
    }

    await _getProfilePhoto();
    _initControllers();
    setState(() => isLoading = false);
  }

  Future<bool> _getMyInfo() async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.me));
    print('la url de profile es ${url}');
    print('el token es ${token}');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final bodyJson = json.decode(response.body);
        print('jo soc');
        print(bodyJson);
        id = bodyJson['id'];
        userProfile = UserProfile(
          firstName: bodyJson['first_name'] ?? '',
          lastName: bodyJson['last_name'] ?? '',
          email: bodyJson['email'] ?? '',
          description: bodyJson['descripcio'] ?? '',
          language: bodyJson['idioma'] ?? '',
          telephone: bodyJson['telefon'] ?? '',
          username: bodyJson['username'] ?? '',
        );
        return true;
      } else {
        print('Failed to get user info: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  // Get profile photo
  Future<void> _getProfilePhoto() async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.profilePhoto));
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${token}',
        },
      );

      if (response.statusCode == 200) {
        final bodyJson = json.decode(response.body);
        print('el get profile foto retorna ${bodyJson}');
        setState(() {
          userProfile.photoUrl = bodyJson['foto'];
        });
      } else if (response.statusCode == 404) {
        // No photo found, that's fine
        print('No profile photo found');
      } else {
        print('Failed to get profile photo: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting profile photo: $e');
    }
  }

  // Upload profile photo
  Future<void> _uploadProfilePhoto(File imageFile) async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.profilePhoto));
    try {
      // Create a multipart request
      var request = http.MultipartRequest('POST', url);

      print('request ${request}');

      // Add authorization header
      request.headers['Authorization'] = 'Bearer ${token}';

      // Add the file
      request.files.add(
        await http.MultipartFile.fromPath('foto', imageFile.path),
      );

      print('request ${request.files}');

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final bodyJson = json.decode(response.body);
        print('upload foto retorna ${bodyJson}' );
        setState(() {
          userProfile.photoUrl = bodyJson['foto'];
          _selectedImage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada correctamente')),
        );
      } else {
        print('Failed to upload photo: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir la foto de perfil')),
        );
      }
    } catch (e) {
      print('Error uploading profile photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al subir la foto de perfil')),
      );
    }
  }

  // Delete profile photo
  Future<void> _deleteProfilePhoto() async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.profilePhoto));
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer ${token}',
        },
      );

      if (response.statusCode == 204) {
        setState(() {
          userProfile.photoUrl = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil eliminada correctamente')),
        );
      } else {
        print('Failed to delete photo: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la foto de perfil')),
        );
      }
    } catch (e) {
      print('Error deleting profile photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar la foto de perfil')),
      );
    }
  }

  // Select image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      await _uploadProfilePhoto(_selectedImage!);
    }
  }

  // Show image source selection dialog
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.profile_select_photo_source),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.loc.profile_gallery),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(context.loc.profile_camera),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            if (userProfile.photoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(context.loc.profile_delete_photo, style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteProfilePhoto();
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.loc.common_cancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.profile_title),
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
          _buildInfoSection(context.loc.profile_name, userProfile.firstName, Icons.person),
          _buildInfoSection(context.loc.profile_surname, userProfile.lastName, Icons.person),
          _buildInfoSection(context.loc.profile_username, userProfile.username, Icons.person),
          _buildInfoSection('Email', userProfile.email, Icons.email),
          _buildInfoSection(context.loc.profile_telf, userProfile.telephone, Icons.phone),
          _buildInfoSection(context.loc.profile_language, userProfile.language, Icons.language),
          const SizedBox(height: 16),
          _buildDescriptionSection(),
          const SizedBox(height: 25),
          _deleteUserButton(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: isEditing ? _showImageSourceDialog : null,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xE278A879),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: _selectedImage != null
                        ? Image.file(
                      _selectedImage!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                        : userProfile.photoUrl != null
                        ? CachedNetworkImage(
                      imageUrl: userProfile.photoUrl!,
                      placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                      errorWidget: (context, url, error) => const Icon(Icons.person, size: 80, color: Colors.white),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                        : const Icon(Icons.person, size: 80, color: Colors.white),
                  ),
                ),
                if (isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.lightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
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
        Text(
          context.loc.profile_about,
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

  Widget _alertDeleteUser() {
    return AlertDialog(
      title: Text(context.loc.profile_delete),
      content: Text(context.loc.profile_confirmation_delete_text),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text(context.loc.common_cancel),
        ),
        TextButton(
          onPressed: () {
            _deleteUser();
          },
          child: Text(context.loc.profile_confirmation_delete),
        ),
      ],
    );
  }
  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildProfileHeader(), // Reuse the profile header with photo
          const SizedBox(height: 24),
          _buildTextField(context.loc.profile_name, firstNameController, Icons.person),
          _buildTextField(context.loc.profile_surname, lastNameController, Icons.person),
          _buildTextField(context.loc.profile_username, usernameController, Icons.person),
          _buildTextField('Email', emailController, Icons.email, keyboardType: TextInputType.emailAddress),
          _buildTextField(context.loc.profile_telf, telephoneController, Icons.phone, keyboardType: TextInputType.phone),
          _buildLanguageDropdown(),
          _buildTextField(context.loc.profile_about, descriptionController, Icons.description, maxLines: 4),
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
            child: Text(context.loc.profile_save_changes),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: context.loc.profile_language,
          prefixIcon: Icon(Icons.language),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedLanguage,
            isDense: true,
            isExpanded: true,
            onChanged: (String? newValue) {
              setState(() {
                selectedLanguage = newValue!;
              });
            },
            items: languages.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
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

  Widget _deleteUserButton() {
    return Center(
      child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return _alertDeleteUser();
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white
          ),
          child: Text(context.loc.profile_delete)),
    );
  }

  Future<void> editUser() async {
    print('Starting editUser function...');
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.user(id)));

    final Map<String, dynamic> data = {
      'first_name': userProfile.firstName,
      'last_name': userProfile.lastName,
      'email': userProfile.email,
      'username': userProfile.username,
      'idioma': userProfile.language,
      'telefon': userProfile.telephone,
      'descripcio': userProfile.description,
      'is_admin': false,
    };

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${token}',
        },
        body: utf8.encode(json.encode(data)),
      );

      if (response.statusCode == 200) {
        print('User profile updated successfully');
      } else {
        print('Failed to update user profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  Future<void> _deleteUser() async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.user(id)));

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer ${token}',
        },
      );

      if (response.statusCode == 204) {
        print('Usuari eliminat correctament');
        await deleteTokens();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );

      } else {
        print('Error al eliminar el usuari: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> deleteTokens() async {
    try {
      await _secureStorage.delete(key: 'access');
      await _secureStorage.delete(key: 'refresh');
      print('Tokens deleted successfully');
    } catch (e) {
      print('Error deleting tokens: $e');
    }
  }

}