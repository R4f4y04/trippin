import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/riverpod/expenses_provider.dart';
import '../../core/riverpod/members_provider.dart';
import '../../core/riverpod/trip_provider.dart';
import '../../ui_components/primary_button.dart';
import '../about/about_screen.dart';
import '../history/trip_history_screen.dart';
import '../settings/settings_screen.dart';
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
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
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
            onStartTrip: _showCreateTripDialog,
            onOpenHistory: _openTripHistory,
            onOpenSettings: _openSettings,
            onOpenAbout: _openAbout,
            onCreateSampleTrip: _createSampleTrip,
          ),
        );
      },
    );
  }

  Future<void> _showCreateTripDialog() async {
    final titleController = TextEditingController();
    final ownerController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Create Trip'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Trip Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerController,
                  decoration:
                      const InputDecoration(labelText: 'Your Name (Owner)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              PrimaryButton(
                label: 'Create',
                isLoading: isSaving,
                onPressed: () async {
                  final title = titleController.text.trim();
                  final ownerName = ownerController.text.trim();
                  if (title.isEmpty || ownerName.isEmpty) {
                    _showSnack('Title and owner name are required');
                    return;
                  }
                  setState(() => isSaving = true);
                  await ref.read(tripControllerProvider.notifier).createTrip(
                        title: title,
                        ownerName: ownerName,
                      );
                  await ref.read(membersControllerProvider.notifier).refresh();
                  await ref.read(expensesControllerProvider.notifier).refresh();
                  if (mounted) {
                    Navigator.of(context).pop();
                    _showSnack('Trip created');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openTripHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TripHistoryScreen()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openAbout() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  Future<void> _createSampleTrip() async {
    await ref.read(tripControllerProvider.notifier).createSampleTrip();
    await ref.read(membersControllerProvider.notifier).refresh();
    await ref.read(expensesControllerProvider.notifier).refresh();
    _showSnack('Sample trip created');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
