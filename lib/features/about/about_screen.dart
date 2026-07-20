import 'package:flutter/material.dart';

/// Redesigned premium AboutScreen.
///
/// Features:
/// - Curved Info Cards matching the Night Owl theme
/// - Clear explanation of offline-first P2P architecture
/// - Made with ☕ in Pakistan in the footer
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About Trippin')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                          child: Icon(
                            Icons.directions_car_filled_outlined,
                            color: colorScheme.primary,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Trippin',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Split bills, not friendships.',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.secondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Info Card 1: Offline-first
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.offline_bolt, color: colorScheme.primary, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '100% Offline-First',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Trippin is designed to work in remote valleys, dams, and highways with zero internet. All records are stored locally.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Card 2: P2P Sync
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.radar, color: colorScheme.secondary, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'P2P Syncing',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Connect locally with other devices using Bluetooth and local Wi-Fi. Sync ledger seamlessly without any central servers.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Version 1.0.0',
                    style: textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Made with ',
                        style: textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                      ),
                      Icon(Icons.local_cafe, size: 12, color: colorScheme.secondary),
                      Text(
                        ' in Pakistan',
                        style: textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                      ),
                    ],
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
