import 'package:flutter/material.dart';

class ClosedBanner extends StatelessWidget {
  final VoidCallback onReopen;

  const ClosedBanner({super.key, required this.onReopen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Trip is closed. Editing is disabled.'),
          ),
          TextButton(onPressed: onReopen, child: const Text('Reopen')),
        ],
      ),
    );
  }
}
