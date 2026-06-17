import 'package:flutter/material.dart';

class AddMemberOptionsSheet extends StatelessWidget {
  final VoidCallback onAddLocalMember;
  final VoidCallback onConnectDevice;

  const AddMemberOptionsSheet({
    super.key,
    required this.onAddLocalMember,
    required this.onConnectDevice,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Member', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Add Locally'),
              subtitle: const Text(
                'For someone without the app — you\'ll manage their expenses.',
              ),
              onTap: onAddLocalMember,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.wifi_tethering),
              title: const Text('Connect a Device'),
              subtitle: const Text(
                'Invite someone nearby to join with their phone.',
              ),
              onTap: onConnectDevice,
            ),
          ],
        ),
      ),
    );
  }
}
