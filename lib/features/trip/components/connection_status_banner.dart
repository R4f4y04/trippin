import 'package:flutter/material.dart';

import '../../../core/models/connection_state.dart';
import '../../../ui_components/primary_button.dart';

class ConnectionStatusBanner extends StatelessWidget {
  final ConnectionStateModel connectionState;
  final int? queuedCount;
  final bool hasUnsyncedItems;
  final bool canAddConnectedGuest;
  final VoidCallback onManageConnection;
  final VoidCallback onAddConnectedGuest;

  const ConnectionStatusBanner({
    super.key,
    required this.connectionState,
    required this.queuedCount,
    required this.hasUnsyncedItems,
    required this.canAddConnectedGuest,
    required this.onManageConnection,
    required this.onAddConnectedGuest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connection', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('Role: ${connectionState.role.name.toUpperCase()}'),
            const SizedBox(height: 4),
            Text('Status: ${connectionState.status.name}'),
            if (connectionState.selectedDevice != null) ...[
              const SizedBox(height: 4),
              Text('Peer: ${connectionState.selectedDevice!.displayName}'),
            ],
            if (connectionState.statusMessage != null) ...[
              const SizedBox(height: 4),
              Text(connectionState.statusMessage!),
            ],
            const SizedBox(height: 4),
            Text(
              queuedCount == null
                  ? 'Queued sync items: ...'
                  : 'Queued sync items: $queuedCount',
            ),
            if (hasUnsyncedItems) ...[
              const SizedBox(height: 8),
              Text(
                'Some items are waiting to sync.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Manage Connection',
              onPressed: onManageConnection,
            ),
            if (canAddConnectedGuest) ...[
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Add Connected Guest As Member',
                onPressed: onAddConnectedGuest,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
