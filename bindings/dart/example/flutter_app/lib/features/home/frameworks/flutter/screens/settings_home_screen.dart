import 'package:flutter/material.dart';
import 'package:flutter_app/features/settings/frameworks/flutter/screens/settings_screen.dart';

/// Wrapper for settings screen in home navigation
/// This keeps the home feature as the entry point while delegating to settings feature
class SettingsHomeScreen extends StatelessWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}
