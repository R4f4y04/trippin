import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/riverpod/expenses_provider.dart';
import '../../core/riverpod/members_provider.dart';
import '../../core/riverpod/profile_provider.dart';
import '../../core/riverpod/trip_provider.dart';
import '../../ui_components/primary_button.dart';

class StartTripScreen extends ConsumerStatefulWidget {
  const StartTripScreen({super.key});

  @override
  ConsumerState<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends ConsumerState<StartTripScreen> {
  final _tripNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill the owner name from the saved profile.
    _loadSavedName();
  }

  Future<void> _loadSavedName() async {
    final savedName = await ref.read(savedNameProvider.future);
    if (savedName != null && savedName.isNotEmpty && mounted) {
      _ownerNameController.text = savedName;
    }
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Start a Trip')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),

          // — Trip name section —
          Text(
            'Name your adventure',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tripNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Trip Name',
              hintText: 'e.g. "Khanpur Dam Weekend"',
            ),
          ),

          const SizedBox(height: 24),

          // — Owner name section —
          Text(
            'What should we call you?',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ownerNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              hintText: 'e.g. "Rafay"',
            ),
          ),

          const SizedBox(height: 24),

          // — Info card —
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "You'll be the host. You can add members and manage expenses once the trip is created.",
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // — Create button —
          PrimaryButton(
            label: "Let's Go! 🚀",
            isLoading: _isCreating,
            onPressed: _isCreating ? null : _createTrip,
          ),
        ],
      ),
    );
  }

  Future<void> _createTrip() async {
    final tripName = _tripNameController.text.trim();
    final ownerName = _ownerNameController.text.trim();

    if (tripName.isEmpty || ownerName.isEmpty) {
      _showSnack('Trip name and your name are required');
      return;
    }

    setState(() => _isCreating = true);

    await ref
        .read(tripControllerProvider.notifier)
        .createTrip(title: tripName, ownerName: ownerName);
    await ref.read(membersControllerProvider.notifier).refresh();
    await ref.read(expensesControllerProvider.notifier).refresh();

    if (!mounted) return;
    setState(() => _isCreating = false);

    // Pop back — AppShell will detect the active trip and show TripScreen.
    Navigator.of(context).pop();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
