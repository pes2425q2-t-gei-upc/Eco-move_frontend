import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../routes/frontend_routes.dart';
import '../l10n/context_ext.dart';
import '../l10n/locale_provider.dart';

class UserProfile {
  String firstName;
  String lastName;
  String email;
  String description;
  String language;
  String telephone;
  String username;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.description,
    required this.language,
    required this.telephone,
    required this.username,
  });
}

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  bool isEditing = false;
  String? token = '';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  late UserProfile userProfile;
  bool isLoading = true;
  int id = -1;

  late String selectedLanguage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    token = await getAccessToken();
    print(token);
    final success = await _getMyInfo();

    if (!success) {
      setState(() => isLoading = false);
      return;
    }

    selectedLanguage = userProfile.language;
    setState(() => isLoading = false);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access');
  }

  Future<bool> _getMyInfo() async {
    final url = Uri.parse(FrontendRoutes.build(FrontendRoutes.me));
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

  void _toggleEditMode() {
    if (isEditing) {
      // Save the current language selection
      _saveLanguage();
    } else {
      // Enter edit mode
      setState(() {
        isEditing = true;
      });
    }
  }

  Future<void> _saveLanguage() async {
    if (id == -1 || token == null) {
      _showError(context.loc.settings_language_change_failed);
      return;
    }

    final Map<String, dynamic> data = {
      'first_name': userProfile.firstName,
      'last_name': userProfile.lastName,
      'email': userProfile.email,
      'username': userProfile.username,
      'idioma': selectedLanguage,
      'telefon': userProfile.telephone,
      'descripcio': userProfile.description,
      'is_admin': false,
    };

    final response = await http.put(
      Uri.parse(FrontendRoutes.build(FrontendRoutes.user(id))),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      // Set frontend language immediately
      Provider.of<LocaleProvider>(context, listen: false)
          .setLocale(Locale(_getLocaleCode(selectedLanguage)));

      _showSuccess(context.loc.settings_language_change_successfull);
      setState(() {
        isEditing = false;
      });
    } else {
      _showError(context.loc.settings_language_change_failed);
    }
  }

  String _getLocaleCode(String language) {
    switch (language) {
      case 'Castellano':
        return 'es';
      case 'Catala':
        return 'ca';
      default:
        return 'en';
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
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
        title: Text(context.loc.settings_language),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _saveLanguage();
                _toggleEditMode();
              } else {
                _toggleEditMode();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRadioOption('English', context.loc.language_en),
          _buildRadioOption('Castellano', context.loc.language_es),
          _buildRadioOption('Catala', context.loc.language_ca),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String code, String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: code,
      groupValue: selectedLanguage,
      onChanged: isEditing
          ? (val) {
              if (val != null) {
                setState(() => selectedLanguage = val);
              }
            }
          : null,
    );
  }
}
