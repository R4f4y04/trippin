import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/connection_state.dart';
import '../../core/models/discovered_device.dart';
import '../../core/riverpod/connection_provider.dart';

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
  DateTime? _requestStartedAt;
  Timer? _waitTicker;

  @override
  void dispose() {
    _nameController.dispose();
    _waitTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<ConnectionStateModel>(connectionControllerProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;

      final wasAwaiting =
          previous?.status == ConnectionStatus.requestSent ||
          previous?.status == ConnectionStatus.awaitingConfirmation;
      final isAwaiting =
          next.status == ConnectionStatus.requestSent ||
          next.status == ConnectionStatus.awaitingConfirmation;

      if (!wasAwaiting && isAwaiting) {
        _requestStartedAt ??= DateTime.now();
        _startWaitTicker();
      } else if (wasAwaiting && !isAwaiting) {
        _requestStartedAt = null;
        _stopWaitTicker();
      }

      final wasConnected = previous?.status == ConnectionStatus.connected;
      final isConnected = next.status == ConnectionStatus.connected;
      if (!wasConnected && isConnected) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Connected to host')));
        Navigator.of(context).pop();
      }

      final isRejected = next.status == ConnectionStatus.disconnected;
      if (wasAwaiting && isRejected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request was rejected')),
        );
      }
    });

    final state = ref.watch(connectionControllerProvider);
    final devices = state.discoveredDevices;
    final isCheckingPermissions =
        state.status == ConnectionStatus.checkingPermissions;
    final isDiscovering = state.status == ConnectionStatus.discovering;
    final isSearching = isCheckingPermissions || isDiscovering;
    final isAwaitingConfirmation =
        state.status == ConnectionStatus.requestSent ||
        state.status == ConnectionStatus.awaitingConfirmation;
    final isPermissionDenied =
        state.status == ConnectionStatus.permissionDenied;
    final hasError =
        state.errorMessage != null && state.errorMessage!.isNotEmpty;

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
                ElevatedButton.icon(
                  onPressed: isSearching || isAwaitingConfirmation
                      ? null
                      : _startDiscovery,
                  icon: const Icon(Icons.search),
                  label: Text(isSearching ? 'Searching...' : 'Find Hosts'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: isDiscovering || isAwaitingConfirmation
                      ? _stopScanningOrRequest
                      : null,
                  child: Text(
                    isAwaitingConfirmation ? 'Cancel Request' : 'Stop',
                  ),
                ),
              ],
            ),
            if (isAwaitingConfirmation) ...[
              const SizedBox(height: 12),
              _PendingRequestCard(
                hostName: state.selectedDevice?.displayName,
                elapsedLabel: _formatElapsedLabel(),
              ),
            ],
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
                isAwaitingConfirmation
                    ? 'Waiting for the host to accept your request...'
                    : isSearching
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

  Future<void> _stopScanningOrRequest() async {
    final state = ref.read(connectionControllerProvider);
    final isAwaitingConfirmation =
        state.status == ConnectionStatus.requestSent ||
        state.status == ConnectionStatus.awaitingConfirmation;

    if (isAwaitingConfirmation) {
      await ref
          .read(connectionControllerProvider.notifier)
          .cancelGuestRequest();
      return;
    }

    await _stopDiscovery();
  }

  Future<void> _connect(DiscoveredDevice device) async {
    _requestStartedAt = DateTime.now();
    _startWaitTicker();

    await ref
        .read(connectionControllerProvider.notifier)
        .requestConnection(device);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connection request sent to ${device.displayName}'),
      ),
    );
  }

  void _startWaitTicker() {
    _waitTicker?.cancel();
    _waitTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _stopWaitTicker() {
    _waitTicker?.cancel();
    _waitTicker = null;
  }

  String _formatElapsedLabel() {
    final startedAt = _requestStartedAt;
    if (startedAt == null) {
      return '0s';
    }

    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    final minutes = elapsed ~/ 60;
    final seconds = elapsed % 60;
    if (minutes == 0) {
      return '${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }
}

class _PendingRequestCard extends StatelessWidget {
  final String? hostName;
  final String elapsedLabel;

  const _PendingRequestCard({
    required this.hostName,
    required this.elapsedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHostName = hostName == null || hostName!.trim().isEmpty
        ? 'Host'
        : hostName!.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waiting for $effectiveHostName to accept...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Elapsed: $elapsedLabel',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
