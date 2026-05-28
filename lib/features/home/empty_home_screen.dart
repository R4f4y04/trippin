import 'package:flutter/material.dart';

import '../../ui_components/primary_button.dart';
import 'components/action_pill.dart';

class EmptyHomeScreen extends StatelessWidget {
  final VoidCallback onStartTrip;
  final VoidCallback onJoinTrip;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAbout;

  const EmptyHomeScreen({
    super.key,
    required this.onStartTrip,
    required this.onJoinTrip,
    required this.onOpenHistory,
    required this.onOpenSettings,
    required this.onOpenAbout,
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
              'Split bills, not friendships.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(label: 'Start a Trip', onPressed: onStartTrip),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onJoinTrip,
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Join a Trip'),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 1,
                  color: colorScheme.onSurface.withOpacity(0.2),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 1,
                  color: colorScheme.onSurface.withOpacity(0.2),
                ),
              ],
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
            const SizedBox(height: 40),
            Text(
              'Works offline. No sign-up needed.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
