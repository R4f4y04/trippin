import 'package:flutter/material.dart';

import '../../../core/models/trip.dart';

/// Navigation drawer for the Trip Screen.
///
/// Provides access to secondary screens (History, Settings, About)
/// without leaving the active trip. Also hosts the "Finish Trip" action
/// for the host role.
class TripNavDrawer extends StatelessWidget {
  final Trip trip;
  final bool isHost;
  final bool isClosed;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAbout;
  final VoidCallback? onFinishTrip;

  const TripNavDrawer({
    super.key,
    required this.trip,
    required this.isHost,
    required this.isClosed,
    required this.onOpenHistory,
    required this.onOpenSettings,
    required this.onOpenAbout,
    this.onFinishTrip,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // — Header —
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✈  Trippin',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trip.title,
                    style: textTheme.bodyLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isHost ? 'Role: Host' : 'Role: Guest',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(),

            // — Navigation links —
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Trip History'),
              onTap: () {
                Navigator.of(context).pop(); // close drawer
                onOpenHistory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                onOpenSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.of(context).pop();
                onOpenAbout();
              },
            ),

            const Spacer(),

            // — Finish Trip (host only, active trip only) —
            if (isHost && !isClosed) ...[
              const Divider(),
              ListTile(
                leading: Icon(Icons.flag, color: colorScheme.error),
                title: Text(
                  'Finish Trip',
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onFinishTrip?.call();
                },
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
