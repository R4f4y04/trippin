import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/connection_state.dart';
import '../../core/models/discovered_device.dart';
import '../../core/riverpod/connection_provider.dart';
import '../../core/utils/animations.dart';
import '../../core/utils/haptics.dart';
import '../../ui_components/primary_button.dart';

class GuestScanScreen extends ConsumerStatefulWidget {
  const GuestScanScreen({super.key});

  @override
  ConsumerState<GuestScanScreen> createState() => _GuestScanScreenState();
}

class _GuestScanScreenState extends ConsumerState<GuestScanScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  Future<void> _startScan() async {
    if (_started) return;
    _started = true;
    await ref.read(connectionControllerProvider.notifier).startGuestScan();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Guest Scan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Role: Guest',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Status: ${state.status.name}'),
                  if (state.statusMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(state.statusMessage!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Nearby Hosts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (state.discoveredDevices.isEmpty)
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                child: Column(
                  children: [
                    PulsingGlow(
                      glowColor: Theme.of(context).colorScheme.secondary,
                      maxRadius: 4.0,
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.radar_rounded,
                          size: 28,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hosts found nearby',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ensure the host has opened their lobby and both devices have Wi-Fi, Bluetooth, and Location services enabled.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...state.discoveredDevices
                .map(
                  (device) =>
                      _DeviceTile(device: device, onTap: _confirmConnect),
                )
                .toList(),
          const SizedBox(height: 20),
          PrimaryButton(
            label: state.status == ConnectionStatus.discovering
                ? 'Scanning...'
                : 'Rescan Nearby Hosts',
            onPressed: state.status == ConnectionStatus.discovering
                ? null
                : () {
                    AppHaptics.lightTap();
                    ref.read(connectionControllerProvider.notifier).startGuestScan();
                  },
          ),
          if (state.status == ConnectionStatus.connected) ...[
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Disconnect',
              onPressed: () {
                AppHaptics.warningBuzz();
                ref.read(connectionControllerProvider.notifier).disconnect();
              },
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              AppHaptics.lightTap();
              await ref
                  .read(connectionControllerProvider.notifier)
                  .stopGuestScan();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Stop Scan'),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            if (state.status == ConnectionStatus.permissionDenied) ...[
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Request Permissions Again',
                onPressed: () => ref
                    .read(connectionControllerProvider.notifier)
                    .requestPermissionsOnly(),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref
                    .read(connectionControllerProvider.notifier)
                    .openPermissionSettings(),
                child: const Text('Open App Settings'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _confirmConnect(DiscoveredDevice device) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Connection'),
        content: Text('Send connection request to ${device.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Connect'),
          ),
        ],
      ),
    );

    if (accepted == true && mounted) {
      await ref
          .read(connectionControllerProvider.notifier)
          .requestConnection(device);
    }
  }
}

class _DeviceTile extends StatelessWidget {
  final DiscoveredDevice device;
  final ValueChanged<DiscoveredDevice> onTap;

  const _DeviceTile({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(device.displayName),
        subtitle: Text('Signal: ${device.signalStrength ?? 'unknown'} dBm'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => onTap(device),
      ),
    );
  }
}
