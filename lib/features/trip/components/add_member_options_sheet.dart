import 'package:flutter/material.dart';

class AddMemberOptionsSheet extends StatelessWidget {
  final VoidCallback onAddLocalMember;
  final VoidCallback onConnectGuest;
  final bool canConnectGuest;

  const AddMemberOptionsSheet({
    super.key,
    required this.onAddLocalMember,
    required this.onConnectGuest,
    required this.canConnectGuest,
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
              title: const Text('Add Local Member'),
              subtitle: const Text(
                'Host tracks expenses for someone not connected.',
              ),
              onTap: onAddLocalMember,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link_outlined),
              title: const Text('Connect Guest as Member'),
              subtitle: Text(
                canConnectGuest
                    ? 'Add the currently connected guest to this trip.'
                    : 'Connect a guest first from Manage Connection.',
              ),
              enabled: canConnectGuest,
              onTap: canConnectGuest ? onConnectGuest : null,
            ),
          ],
        ),
      ),
    );
  }
}
