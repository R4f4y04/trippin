import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/expense.dart';
import '../../core/models/trip.dart';
import '../../core/riverpod/trip_list_provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/currency_format.dart';
import '../../ui_components/primary_button.dart';
import 'trip_detail_screen.dart';

/// Redesigned Premium Trip History Screen.
///
/// Features:
/// - Curved cards with trip title, member count, expense count, total amount (₨ formatted)
/// - Color-coded status badges: "Finished ✓" or "Active 🚀"
/// - Swipe-to-delete (right-to-left) with a beautiful red background and double-confirmation dialog
/// - High-fidelity empty state featuring compass icon and clear CTA guidance
class TripHistoryScreen extends ConsumerWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trip History')),
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: 'Failed to load trips',
          onRetry: () => ref.read(tripListControllerProvider.notifier).refresh(),
        ),
        data: (trips) {
          if (trips.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final trip = trips[index];
              return _buildDismissibleCard(context, ref, trip);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: colorScheme.outline.withValues(alpha: 0.1),
              child: Icon(
                Icons.explore_outlined,
                size: 36,
                color: colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No trips yet',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new trip from the home screen to begin tracking expenses!',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleCard(BuildContext context, WidgetRef ref, Trip trip) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(trip.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, ref, trip),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: colorScheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.error, size: 24),
      ),
      child: _TripHistoryCard(
        trip: trip,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TripDetailScreen(tripId: trip.id),
          ),
        ),
        onDelete: () async {
          final confirmed = await _confirmDelete(context, ref, trip);
          if (confirmed == true) {
            await ref.read(tripListControllerProvider.notifier).deleteTrip(trip.id);
          }
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text('Are you sure you want to permanently delete "${trip.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TripHistoryCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TripHistoryCard({
    required this.trip,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return FutureBuilder<List<Expense>>(
      future: StorageService.instance.getExpensesByTrip(trip.id),
      builder: (context, snapshot) {
        final expenses = snapshot.data ?? [];
        final totalSpent = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Title + Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          trip.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(colorScheme),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Subtitles: Date + members/expenses counts
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.outline),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(trip.createdAt),
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                      ),
                      const SizedBox(width: 14),
                      Icon(Icons.people_outline, size: 14, color: colorScheme.outline),
                      const SizedBox(width: 6),
                      Text(
                        '${trip.memberIds.length}',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Bottom Row: Total spent + Delete Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Spent',
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatPKR(totalSpent),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: colorScheme.error.withValues(alpha: 0.7)),
                        onPressed: onDelete,
                        splashRadius: 20,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ColorScheme colorScheme) {
    final isClosed = trip.isClosed;
    final color = isClosed ? const Color(0xFF4ADE80) : colorScheme.secondary;
    final label = isClosed ? 'Finished' : 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
