import 'package:flutter/material.dart';

import '../../../core/models/trip_history_event.dart';
import '../../../core/utils/currency_format.dart';

/// Chronological timeline of trip activity events.
///
/// Each event is rendered with a colored dot and relative timestamp.
/// Event types are color-coded: green (additions), blue (edits),
/// red (deletions), purple (trip lifecycle).
class ActivityTimeline extends StatelessWidget {
  final List<TripHistoryEvent> events;

  const ActivityTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timeline,
                size: 40,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Trip activity will appear here',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventRow(context, event);
      },
    );
  }

  Widget _buildEventRow(BuildContext context, TripHistoryEvent event) {
    final textTheme = Theme.of(context).textTheme;
    final dotColor = _dotColor(event.type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.summary,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo(event.createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _dotColor(String type) {
    switch (type) {
      case 'CREATE_TRIP':
      case 'CLOSE_TRIP':
      case 'REOPEN_TRIP':
        return const Color(0xFF7C4DFF); // Purple - lifecycle
      case 'ADD_MEMBER':
      case 'ADD_EXPENSE':
        return const Color(0xFF4ADE80); // Green - additions
      case 'EDIT_EXPENSE':
        return const Color(0xFF3B82F6); // Blue - edits
      case 'DELETE_EXPENSE':
        return const Color(0xFFFF6B6B); // Red - deletions
      default:
        return const Color(0xFF9AA4C7); // Muted - unknown
    }
  }
}
