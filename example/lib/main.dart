import 'package:flutter/material.dart';
import 'package:scppg/scppg.dart';
import 'package:get_it/get_it.dart';

import 'scppg_app.dart';

/// Register core services and controllers in GetIt
void _registerDependencies() {
  // Register SCPPG controller as singleton
  GetIt.instance.registerSingleton<ScppgController>(ScppgController(fps: 30));
}

/// Main entry point of the application
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register dependencies
  _registerDependencies();

  // Initialize SCPPG controller
  await GetIt.instance<ScppgController>().init();

  runApp(const ScppgApp());
}
