import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'user_profile.dart';
import 'package:eco_move_frontend/page/language_settings.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'car-info.dart';
import 'package:eco_move_frontend/user_trophies.dart';

class NavigationPage extends StatefulWidget {
  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.loc.settings_title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Settings options cards
              _buildSettingCard(
                context,
                icon: Icons.language,
                title: context.loc.settings_change_language,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => LanguageSettingsPage()),
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildSettingCard(
                context,
                icon: Icons.person,
                title: context.loc.settings_my_profile,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => UserProfilePage()),
                  );
                },
              ),

              const SizedBox(height: 16),
              _buildSettingCard(
                context,
                icon: Icons.directions_car,
                title: context.loc.car_info,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => CarInfo()),
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildSettingCard(
                context,
                icon: Icons.emoji_events,
                title: context.loc.settings_my_trophies,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const UserTrophiesPage()),
                  );
                },
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}