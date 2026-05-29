import 'package:flutter/material.dart';

import '../../../core/models/trip.dart';
import '../../../core/utils/currency_format.dart';

/// Persistent header above the tab bar showing trip info, total spent,
/// and the device owner's personal balance.
class TripHeader extends StatelessWidget {
  final Trip trip;
  final int memberCount;
  final double totalSpent;
  final double personalBalance;

  const TripHeader({
    super.key,
    required this.trip,
    required this.memberCount,
    required this.totalSpent,
    required this.personalBalance,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final balanceColor =
        personalBalance >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFFF6B6B);
    final balancePrefix = personalBalance >= 0 ? '+' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip subtitle
          Text(
            'Started ${timeAgo(trip.createdAt)} · $memberCount members',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),

          // Total spent card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Spent',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPKR(totalSpent),
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your balance: $balancePrefix${formatPKR(personalBalance.abs())}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: balanceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
