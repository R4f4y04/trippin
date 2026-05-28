import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../about/about_screen.dart';
import '../history/trip_history_screen.dart';
import '../join_trip/join_trip_entry_screen.dart';
import '../settings/settings_screen.dart';
import '../start_trip/start_trip_screen.dart';
import 'empty_home_screen.dart';

/// Home Hub screen — shown ONLY when there is no active trip.
///
/// Routing between Home Hub and Trip Screen is handled by [AppShell]
/// in main.dart. This widget simply displays the hub with navigation actions.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: EmptyHomeScreen(
        onStartTrip: () => _openStartTrip(context),
        onJoinTrip: () => _openJoinTrip(context),
        onOpenHistory: () => _openTripHistory(context),
        onOpenSettings: () => _openSettings(context),
        onOpenAbout: () => _openAbout(context),
      ),
    );
  }

  void _openStartTrip(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StartTripScreen()),
    );
  }

  void _openJoinTrip(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JoinTripEntryScreen()),
    );
  }

  void _openTripHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TripHistoryScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openAbout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }
}
