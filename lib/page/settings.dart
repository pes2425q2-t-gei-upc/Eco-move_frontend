import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:eco_move_frontend/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../l10n/locale_provider.dart';
import 'package:http/http.dart' as http;
import 'package:eco_move_frontend/config.dart';

class SettingsPage extends StatefulWidget {
  final int userId;
  const SettingsPage({super.key, required this.userId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'en';
    });
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

    // Sync to backend
    final response = await http.put(
      Uri.parse(
        FrontendRoutes.build(FrontendRoutes.updateUserLanguage(widget.userId)),
      ),
      headers: {'Content-Type': 'application/json'},
      body: '{"idioma": "${_mapToBackendLang(languageCode)}"}',
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
