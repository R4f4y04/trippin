import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/connection_state.dart';
import '../../core/models/discovered_device.dart';
import '../../core/riverpod/connection_provider.dart';
import '../../core/riverpod/profile_provider.dart';
import '../../core/riverpod/trip_provider.dart';
import '../../core/services/storage_service.dart';
import '../../ui_components/primary_button.dart';

/// Redesigned Join Trip Entry Screen for guests.
///
/// Features:
/// - "What should we call you?" Name input auto-filled from ProfileService
/// - Discovered hosts represented as modern styled cards with signal strength
/// - Empty state with friendly troubleshooting tips
/// - Progress dialogs / loading overlays for connection requests
/// - Automatic persistence of name/deviceRole and navigation to TripScreen upon successful sync
class JoinTripEntryScreen extends ConsumerStatefulWidget {
  const JoinTripEntryScreen({super.key});

  @override
  ConsumerState<JoinTripEntryScreen> createState() =>
      _JoinTripEntryScreenState();
}

class _JoinTripEntryScreenState extends ConsumerState<JoinTripEntryScreen> {
  final _nameController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSavedName();
  }

  Future<void> _loadSavedName() async {
    final savedName = await ref.read(savedNameProvider.future);
    if (savedName != null && savedName.isNotEmpty && mounted) {
      _nameController.text = savedName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startDiscovery() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Please enter your name first');
      return;
    }

    setState(() => _isSearching = true);
    await ref.read(connectionControllerProvider.notifier).startGuestScan();
  }

  Future<void> _stopDiscovery() async {
    await ref.read(connectionControllerProvider.notifier).stopGuestScan();
    if (!mounted) return;
    setState(() => _isSearching = false);
  }

  Future<void> _connect(DiscoveredDevice device) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Please enter your name first');
      return;
    }

    // Stop scanning while connecting
    await _stopDiscovery();

    if (!mounted) return;

    // Show progress dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Connecting to host...')),
          ],
        ),
      ),
    );

    // Save name/owner details early so host's handshake can resolve it
    await ref.read(savedNameProvider.notifier).updateName(name);
    await StorageService.instance.setOrCreateDeviceOwner(name: name);

    await ref
        .read(connectionControllerProvider.notifier)
        .requestConnection(device);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionControllerProvider);
    final devices = state.discoveredDevices;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Listen for successful connection state transition
    ref.listen<ConnectionStateModel>(connectionControllerProvider, (prev, next) async {
      if (next.status == ConnectionStatus.connected) {
        // Pop the progress dialog
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Persist guest role
        await ref.read(deviceRoleProvider.notifier).setRole('guest');

        // Refresh trip provider so AppShell redirects to TripScreen
        await ref.read(tripControllerProvider.notifier).refresh();

        if (mounted) {
          _showSnack('Connected successfully! 🎉');
          // Pop this screen
          Navigator.of(context).pop();
        }
      } else if (next.status == ConnectionStatus.error) {
        // Pop the progress dialog if open
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (mounted && next.errorMessage != null) {
          _showSnack(next.errorMessage!);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Join a Trip')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // — User Name Section —
            Text(
              'What should we call you?',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'e.g. "Rafay"',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 24),

            // — Instruction Section —
            Text(
              'Find nearby hosts and join a trip. Keep Bluetooth and Location enabled.',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: 16),

            // — Discovery Control Row —
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: _isSearching ? 'Searching...' : 'Find Hosts',
                    onPressed: _isSearching ? null : _startDiscovery,
                  ),
                ),
                if (_isSearching) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _stopDiscovery,
                    child: const Text('Stop'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // — Discovered Devices / Empty State —
            Expanded(
              child: devices.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      itemCount: devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return _buildHostCard(context, device);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.radar,
                size: 48,
                color: colorScheme.outline.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No hosts found nearby',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Troubleshooting tips:\n'
                '• Ensure host has opened the Host Lobby\n'
                '• Enable Bluetooth & Location on both devices\n'
                '• Keep devices within 10 meters',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHostCard(BuildContext context, DiscoveredDevice device) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _connect(device),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(
                  Icons.wifi_tethering,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.displayName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Host Code: ${device.endpointId}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
