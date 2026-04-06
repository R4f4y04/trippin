import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/connection_state.dart';
import '../../core/models/discovered_device.dart';
import '../../core/riverpod/connection_provider.dart';

class JoinTripEntryScreen extends ConsumerStatefulWidget {
  const JoinTripEntryScreen({super.key});

  @override
  ConsumerState<JoinTripEntryScreen> createState() =>
      _JoinTripEntryScreenState();
}

class _JoinTripEntryScreenState extends ConsumerState<JoinTripEntryScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionControllerProvider);
    final devices = state.discoveredDevices;
    final isCheckingPermissions =
        state.status == ConnectionStatus.checkingPermissions;
    final isDiscovering = state.status == ConnectionStatus.discovering;
    final isSearching = isCheckingPermissions || isDiscovering;
    final isPermissionDenied =
        state.status == ConnectionStatus.permissionDenied;
    final hasError =
        state.errorMessage != null && state.errorMessage!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Join Trip as Guest')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find nearby hosts and join a trip lobby. Keep Bluetooth and Location enabled.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: isSearching ? null : _startDiscovery,
                  icon: const Icon(Icons.search),
                  label: Text(isSearching ? 'Searching...' : 'Find Hosts'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: isDiscovering ? _stopDiscovery : null,
                  child: const Text('Stop'),
                ),
              ],
            ),
            if (state.statusMessage != null &&
                state.statusMessage!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                state.statusMessage!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (hasError) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            if (isPermissionDenied) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(connectionControllerProvider.notifier)
                    .openPermissionSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Open Permission Settings'),
              ),
            ],
            const SizedBox(height: 16),
            if (devices.isEmpty)
              Text(
                isSearching
                    ? 'Searching for nearby hosts...'
                    : 'No hosts discovered yet. Tap Find Hosts to scan again.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: devices.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: const Icon(Icons.phone_android),
                      title: Text(device.displayName),
                      subtitle: Text(device.endpointId),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _connect(device),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDiscovery() async {
    await ref.read(connectionControllerProvider.notifier).startGuestScan();
  }

  Future<void> _stopDiscovery() async {
    await ref.read(connectionControllerProvider.notifier).stopGuestScan();
  }

  Future<void> _connect(DiscoveredDevice device) async {
    await ref
        .read(connectionControllerProvider.notifier)
        .requestConnection(device);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Connection request sent')));
    Navigator.of(context).pop();
  }
}
