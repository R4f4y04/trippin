import 'package:flutter/material.dart';

import '../../ui_components/primary_button.dart';
import 'components/action_pill.dart';

class EmptyHomeScreen extends StatelessWidget {
  final VoidCallback onStartTrip;
  final VoidCallback onJoinTrip;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAbout;
  final VoidCallback onCreateSampleTrip;

  const EmptyHomeScreen({
    super.key,
    required this.onStartTrip,
    required this.onJoinTrip,
    required this.onOpenHistory,
    required this.onOpenSettings,
    required this.onOpenAbout,
    required this.onCreateSampleTrip,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trippin',
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Offline-first expense splitting.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Start Trip as Host', onPressed: onStartTrip),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onJoinTrip,
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Join a Trip as Guest'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onCreateSampleTrip,
              child: const Text('Create sample trip'),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ActionPill(
                  label: 'History',
                  icon: Icons.history,
                  onPressed: onOpenHistory,
                ),
                ActionPill(
                  label: 'Settings',
                  icon: Icons.settings,
                  onPressed: onOpenSettings,
                ),
                ActionPill(
                  label: 'About',
                  icon: Icons.info_outline,
                  onPressed: onOpenAbout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
