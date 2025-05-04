import 'dart:convert';
import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:flutter/material.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../l10n/locale_provider.dart';
import 'package:http/http.dart' as http;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'en';
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language') ?? 'en';
    final token = prefs.getString('accessToken');

    setState(() {
      _selectedLanguage = savedLang;
    });

    if (token != null) {
      final response = await http.get(
        Uri.parse(FrontendRoutes.build(FrontendRoutes.me)),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userId = data['id'];
        });
      } else {
        print("Failed to fetch user ID from /me/: ${response.statusCode}");
      }
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);

    Provider.of<LocaleProvider>(
      context,
      listen: false,
    ).setLocale(Locale(languageCode));

    setState(() {
      _selectedLanguage = languageCode;
    });

    if (_userId == null) {
      print("User ID not loaded yet.");
      return;
    }

    final token = prefs.getString('accessToken');
    // Sync to backend
    final response = await http.put(
      Uri.parse(
        FrontendRoutes.build(FrontendRoutes.updateUserLanguage(_userId!)),
      ),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'idioma': _mapToBackendLang(languageCode)}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.settings_language_change_successfull),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.settings_language_change_failed),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _mapToBackendLang(String langCode) {
    switch (langCode) {
      case 'ca':
        return 'Català';
      case 'es':
        return 'Castellano';
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.loc.settings_language)),
      body: Column(
        children: [
          RadioListTile<String>(
            title: Text(context.loc.language_en),
            value: 'en',
            groupValue: _selectedLanguage,
            onChanged: (val) => _changeLanguage(val!),
          ),
          RadioListTile<String>(
            title: Text(context.loc.language_es),
            value: 'es',
            groupValue: _selectedLanguage,
            onChanged: (val) => _changeLanguage(val!),
          ),
          RadioListTile<String>(
            title: Text(context.loc.language_ca),
            value: 'ca',
            groupValue: _selectedLanguage,
            onChanged: (val) => _changeLanguage(val!),
          ),
        ],
      ),
    );
  }
}
