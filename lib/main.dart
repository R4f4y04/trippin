import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/safe_execute.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await safeExecute(
    operation: () => StorageService.instance.initialize(),
    onError: (error, stackTrace) {
      AppLogger.error('Storage initialization failed', error, stackTrace);
    },
  );
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.nightOwl(),
      home: const HomeScreen(),
    );
  }
}
