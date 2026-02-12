import 'package:flutter/material.dart';

import '../../ui_components/primary_button.dart';
import 'guest_scan_screen.dart';
import 'host_lobby_screen.dart';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Devices')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Phase 2 Handshake',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Set up a nearby host/guest connection. Data sync is added in Phase 3.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Host', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a local lobby and accept one nearby guest connection.',
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Start as Host',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HostLobbyScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Guest', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan nearby lobbies and request to connect to one host.',
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Start as Guest',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GuestScanScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
