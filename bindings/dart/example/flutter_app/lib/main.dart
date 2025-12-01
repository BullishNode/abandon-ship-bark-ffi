import 'package:flutter/material.dart';
import 'package:flutter_app/core/frameworks/get_it/injection_container.dart';
import 'package:flutter_app/core/frameworks/flutter/bark_app.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await initializeDependencies();

  runApp(const BarkApp());
}
