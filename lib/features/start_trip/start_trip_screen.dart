import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/riverpod/expenses_provider.dart';
import '../../core/riverpod/members_provider.dart';
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
  void dispose() {
    _tripNameController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Trip as Host')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Create your trip and become the host. As host, you control the lobby, canonical sync, and trip closure.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tripNameController,
            decoration: const InputDecoration(labelText: 'Trip Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ownerNameController,
            decoration: const InputDecoration(labelText: 'Your Name'),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Create Trip',
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

    try {
      await ref
          .read(tripControllerProvider.notifier)
          .createTrip(title: tripName, ownerName: ownerName);
      await ref.read(membersControllerProvider.notifier).refresh();
      await ref.read(expensesControllerProvider.notifier).refresh();

      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack('Trip created');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to create trip. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
