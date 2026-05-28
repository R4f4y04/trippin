import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/profile_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/safe_execute.dart';
import 'features/home/home_screen.dart';
import 'features/trip/trip_screen.dart';
import 'core/riverpod/trip_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await safeExecute(
    operation: () => StorageService.instance.initialize(),
    onError: (error, stackTrace) {
      AppLogger.error('Storage initialization failed', error, stackTrace);
    },
  );
  await safeExecute(
    operation: () => ProfileService.instance.initialize(),
    onError: (error, stackTrace) {
      AppLogger.error('Profile initialization failed', error, stackTrace);
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
      home: const AppShell(),
    );
  }
}

/// Root shell that determines whether to show the Trip Screen or Home Hub.
///
/// If an active (non-closed) trip exists → go directly to [TripScreen].
/// Otherwise → show [HomeScreen] (Home Hub).
///
/// This ensures crash recovery: if the app dies mid-trip, relaunching
/// drops the user right back into the trip, not the home screen.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripControllerProvider);

    return tripAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load app state'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(tripControllerProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (trip) {
        if (trip != null) {
          return const TripScreen();
        }
        return const HomeScreen();
      },
    );
  }
}
