import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/riverpod/profile_provider.dart';
import '../../core/riverpod/trip_provider.dart';
import '../../core/services/storage_service.dart';

/// Redesigned premium Settings Screen.
///
/// Features:
/// - Editable "Your Name" synced with ProfileService and Local Storage device owner
/// - Reset all data action with double confirmation dialogue
/// - Dynamic list cards matching Night Owl theme
/// - Offline-first info display
/// - Pakistani-flavored footer
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Your Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Your Name',
            hintText: 'e.g. Rafay',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await ref.read(savedNameProvider.notifier).updateName(newName);
      await StorageService.instance.setOrCreateDeviceOwner(name: newName);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetAllData(BuildContext context, WidgetRef ref) async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'Are you sure you want to delete all trips, members, and expenses? This action is permanent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    if (!context.mounted) return;

    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reset'),
        content: const Text(
          'This will permanently delete everything. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'PERMANENTLY RESET',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm2 != true) return;

    // Reset all states
    await StorageService.instance.clearAllData();
    await ref.read(savedNameProvider.notifier).updateName('');
    await ref.read(deviceRoleProvider.notifier).setRole(null);
    await ref.read(tripControllerProvider.notifier).clearActiveTrip();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data has been reset.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop(); // Back to Home Screen
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedNameAsync = ref.watch(savedNameProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Profile Section Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: savedNameAsync.when(
                      loading: () => const ListTile(
                        title: Text('Loading profile...'),
                      ),
                      error: (_, __) => const ListTile(
                        title: Text('Error loading profile'),
                      ),
                      data: (name) {
                        final displayName = (name == null || name.isEmpty) ? 'Not Set' : name;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                            child: Icon(Icons.person, color: colorScheme.primary),
                          ),
                          title: const Text(
                            'Your Display Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(displayName),
                          trailing: const Icon(Icons.edit, size: 18),
                          onTap: () => _editName(context, ref, name ?? ''),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Preferences Group
                  Text(
                    'Preferences',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.dark_mode_outlined),
                          title: const Text('Theme'),
                          subtitle: const Text('Night Owl (default)'),
                          trailing: const Icon(Icons.check, color: Colors.green),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Theme customization is planned for a future update.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Info Group
                  Text(
                    'Application Info',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.offline_bolt_outlined),
                          title: const Text('Database Mode'),
                          subtitle: const Text('Offline-first • Local Hive storage'),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.security_outlined),
                          title: const Text('Privacy'),
                          subtitle: const Text('Your data never leaves your device unless synced'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Danger Zone Card
                  Card(
                    elevation: 0,
                    color: colorScheme.error.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.delete_forever, color: colorScheme.error),
                      title: Text(
                        'Reset All Data',
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('Permanently wipe all trips, members, and settings'),
                      onTap: () => _resetAllData(context, ref),
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
                    'Trippin v1.0.0',
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
