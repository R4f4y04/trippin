import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About Trippin')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trippin', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Offline-first expense splitting for group trips.',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'No internet required. Data stays on your device until you choose to sync.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text('Version 0.1.0', style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
