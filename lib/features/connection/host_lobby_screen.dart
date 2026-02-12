import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/connection_state.dart';
import '../../core/riverpod/connection_provider.dart';
import '../../ui_components/primary_button.dart';

class HostLobbyScreen extends ConsumerStatefulWidget {
  const HostLobbyScreen({super.key});

  @override
  ConsumerState<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends ConsumerState<HostLobbyScreen> {
  bool _started = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startHost();
    });
  }

  Future<void> _startHost() async {
    if (_started) return;
    _started = true;
    await ref
        .read(connectionControllerProvider.notifier)
        .startHost(hostName: 'Trippin Host');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionControllerProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (state.status == ConnectionStatus.requestIncoming && !_dialogOpen) {
        _dialogOpen = true;
        _showIncomingRequestDialog();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Host Lobby')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(state: state),
          const SizedBox(height: 12),
          if (state.status == ConnectionStatus.connected) ...[
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Disconnect Guest',
              onPressed: () =>
                  ref.read(connectionControllerProvider.notifier).disconnect(),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await ref.read(connectionControllerProvider.notifier).stopHost();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Stop Lobby'),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showIncomingRequestDialog() async {
    final state = ref.read(connectionControllerProvider);
    final guestName = state.selectedDevice?.displayName ?? 'Nearby Guest';

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Connection Request'),
        content: Text('Allow $guestName to connect?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Reject'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    await ref
        .read(connectionControllerProvider.notifier)
        .hostRespondToIncomingRequest(accept: accepted == true);

    _dialogOpen = false;
  }
}

class _StatusCard extends StatelessWidget {
  final ConnectionStateModel state;

  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: Host', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Status: ${state.status.name}'),
            if (state.statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(state.statusMessage!),
            ],
            if (state.activeConnectionId != null) ...[
              const SizedBox(height: 8),
              Text('Connection ID: ${state.activeConnectionId}'),
            ],
          ],
        ),
      ),
    );
  }
}
