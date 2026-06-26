import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/connection_state.dart';
import '../../core/riverpod/connection_provider.dart';
import '../../core/riverpod/trip_provider.dart';
import '../../ui_components/primary_button.dart';

/// Highly premium Host Lobby Screen featuring a broadcasting radar animation,
/// active trip info, guest list, and instruction card.
/// Automatically accepts and adds guests as members.
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

    final tripAsync = ref.read(tripControllerProvider);
    final tripTitle = tripAsync.value?.title ?? 'Trippin Trip';

    await ref
        .read(connectionControllerProvider.notifier)
        .startHost(hostName: 'Host: $tripTitle');
  }



  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionControllerProvider);
    final tripAsync = ref.watch(tripControllerProvider);

    final trip = tripAsync.value;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (state.status == ConnectionStatus.requestIncoming && !_dialogOpen) {
        _dialogOpen = true;
        _showIncomingRequestDialog();
      }
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Host Lobby')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Radar Animation Box
            if (state.status == ConnectionStatus.advertising) ...[
              const SizedBox(height: 16),
              const BroadcastingRadar(),
              const SizedBox(height: 24),
              Text(
                'Broadcasting Lobby...',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const SizedBox(height: 16),
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.outline.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.wifi_tethering_off,
                    color: colorScheme.outline,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Lobby inactive',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              state.statusMessage ?? 'Configuring lobby...',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Trip & Lobby Details Card
            if (trip != null) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip Name',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip.title,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      Text(
                        'Lobby Status',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.status == ConnectionStatus.connected
                            ? 'Connected to Guest'
                            : 'Awaiting connection...',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: state.status == ConnectionStatus.connected
                              ? colorScheme.secondary
                              : colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Instruction Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: colorScheme.secondary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to connect guests:',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '1. Ask guest to select "Join a Trip" on their device.\n'
                          '2. Have them find and tap your lobby ("Host: ${trip?.title ?? '...'}")\n'
                          '3. Accept their incoming request on this device.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Actions Row
            if (state.status == ConnectionStatus.connected) ...[
              PrimaryButton(
                label: 'Disconnect Guest',
                onPressed: () =>
                    ref.read(connectionControllerProvider.notifier).disconnect(),
              ),
              const SizedBox(height: 12),
            ] else if (state.status != ConnectionStatus.advertising &&
                state.status != ConnectionStatus.checkingPermissions) ...[
              PrimaryButton(
                label: 'Restart Lobby',
                onPressed: () => _startHost(),
              ),
              const SizedBox(height: 12),
            ],

            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await ref.read(connectionControllerProvider.notifier).stopHost();
                navigator.pop();
              },
              child: Text(
                'Stop & Close Lobby',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          ],
        ),
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
        content: Text('Allow $guestName to join this trip?'),
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

/// A custom pulsing radar animation for advertising hosts.
class BroadcastingRadar extends StatefulWidget {
  const BroadcastingRadar({super.key});

  @override
  State<BroadcastingRadar> createState() => _BroadcastingRadarState();
}

class _BroadcastingRadarState extends State<BroadcastingRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Center(
      child: SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(3, (index) {
              final animation = Tween<double>(begin: 0.1, end: 1.0).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: Interval(index * 0.25, 1.0, curve: Curves.easeOut),
                ),
              );

              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Container(
                    width: 140 * animation.value,
                    height: 140 * animation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 1.0 - animation.value),
                        width: 1.5,
                      ),
                    ),
                  );
                },
              );
            }),
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(
                Icons.wifi_tethering,
                color: color,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
