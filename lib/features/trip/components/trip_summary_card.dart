import 'package:flutter/material.dart';

import '../../../core/models/trip.dart';

class TripSummaryCard extends StatelessWidget {
  final Trip trip;
  final int memberCount;

  const TripSummaryCard({
    super.key,
    required this.trip,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Join Code: ${trip.joinCode}'),
            const SizedBox(height: 4),
            Text('Members: $memberCount'),
          ],
        ),
      ),
    );
  }
}
