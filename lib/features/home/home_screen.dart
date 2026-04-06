import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/riverpod/expenses_provider.dart';
import '../../core/riverpod/members_provider.dart';
import '../../core/riverpod/trip_provider.dart';
import '../about/about_screen.dart';
import '../history/trip_history_screen.dart';
import '../join_trip/join_trip_entry_screen.dart';
import '../settings/settings_screen.dart';
import '../start_trip/start_trip_screen.dart';
import '../trip/components/error_state.dart';
import '../trip/trip_screen.dart';
import 'empty_home_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripControllerProvider);

    return tripAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: ErrorState(
          message: 'Failed to load trip',
          onRetry: () => ref.read(tripControllerProvider.notifier).refresh(),
        ),
      ),
      data: (trip) {
        if (trip != null) {
          return const TripScreen();
        }

        return Scaffold(
          body: EmptyHomeScreen(
            onStartTrip: _openStartTrip,
            onJoinTrip: _openJoinTrip,
            onOpenHistory: _openTripHistory,
            onOpenSettings: _openSettings,
            onOpenAbout: _openAbout,
            onCreateSampleTrip: _createSampleTrip,
          ),
        );
      },
    );
  }

  Future<void> _openStartTrip() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StartTripScreen()));
  }

  Future<void> _openJoinTrip() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const JoinTripEntryScreen()));
  }

  void _openTripHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TripHistoryScreen()));
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  void _openAbout() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
  }

  Future<void> _createSampleTrip() async {
    await ref.read(tripControllerProvider.notifier).createSampleTrip();
    await ref.read(membersControllerProvider.notifier).refresh();
    await ref.read(expensesControllerProvider.notifier).refresh();
    _showSnack('Sample trip created');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
