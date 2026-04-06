import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/discovered_device.dart';
import '../../core/riverpod/connection_provider.dart';

class JoinTripEntryScreen extends ConsumerStatefulWidget {
  const JoinTripEntryScreen({super.key});

  @override
  ConsumerState<JoinTripEntryScreen> createState() =>
      _JoinTripEntryScreenState();
}

class _JoinTripEntryScreenState extends ConsumerState<JoinTripEntryScreen> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionControllerProvider);
    final devices = state.discoveredDevices;

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
                  onPressed: _isSearching ? null : _startDiscovery,
                  icon: const Icon(Icons.search),
                  label: Text(_isSearching ? 'Searching...' : 'Find Hosts'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _isSearching ? _stopDiscovery : null,
                  child: const Text('Stop'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (devices.isEmpty)
              Text(
                'No hosts discovered yet.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
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
    setState(() => _isSearching = true);
    await ref.read(connectionControllerProvider.notifier).startGuestScan();
  }

  Future<void> _stopDiscovery() async {
    await ref.read(connectionControllerProvider.notifier).stopGuestScan();
    if (!mounted) return;
    setState(() => _isSearching = false);
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
