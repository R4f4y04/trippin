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

          // Glassmorphic Total Spent Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  colorScheme.surface.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL SPENT',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 16,
                      color: colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: totalSpent),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutExpo,
                  builder: (context, value, child) {
                    return Text(
                      formatPKR(value),
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: colorScheme.onSurface,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Divider(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                  height: 1,
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: personalBalance.abs()),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutExpo,
                  builder: (context, value, child) {
                    return Row(
                      children: [
                        Icon(
                          personalBalance >= 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 14,
                          color: balanceColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Your balance: $balancePrefix${formatPKR(value)}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: balanceColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
