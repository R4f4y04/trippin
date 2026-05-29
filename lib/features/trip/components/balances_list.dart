import 'package:flutter/material.dart';

import '../../../core/utils/currency_format.dart';
import '../../../core/utils/member_colors.dart';

/// Visual balance bars showing each member's net position.
///
/// Positive balances (owed money) show green bars extending right.
/// Negative balances (owes money) show red bars extending left.
/// Bar widths are proportional to the maximum absolute balance.
class BalancesList extends StatelessWidget {
  final Map<String, double> balances;
  final Map<String, String> memberMap;

  /// Maps member ID → index in the trip's member list, for color assignment.
  final Map<String, int> memberIndexMap;

  const BalancesList({
    super.key,
    required this.balances,
    required this.memberMap,
    required this.memberIndexMap,
  });

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.balance,
                size: 40,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Add expenses to see balances',
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

    final entries = balances.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxAbs =
        entries.map((e) => e.value.abs()).reduce((a, b) => a > b ? a : b);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: entries.length + 1, // +1 for settlement placeholder
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == entries.length) {
          return _buildSettlementPlaceholder(context);
        }
        final entry = entries[index];
        return _buildBalanceBar(context, entry.key, entry.value, maxAbs);
      },
    );
  }

  Widget _buildBalanceBar(
    BuildContext context,
    String memberId,
    double balance,
    double maxAbs,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final memberIndex = memberIndexMap[memberId] ?? 0;
    final memberColor = getMemberColor(memberIndex);
    final name = memberMap[memberId] ?? 'Unknown';
    final isPositive = balance >= 0;
    final barColor =
        isPositive ? const Color(0xFF4ADE80) : const Color(0xFFFF6B6B);
    final fraction = maxAbs > 0 ? balance.abs() / maxAbs : 0.0;

    return Row(
      children: [
        // Member color dot + name
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: memberColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            name,
            style: textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),

        // Balance bar
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth * fraction;
              return Align(
                alignment:
                    isPositive ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  height: 14,
                  width: barWidth.clamp(4.0, constraints.maxWidth),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),

        // Amount
        SizedBox(
          width: 85,
          child: Text(
            '${isPositive ? '+' : ''}${formatPKR(balance.abs())}',
            textAlign: TextAlign.right,
            style: textTheme.bodyMedium?.copyWith(
              color: barColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementPlaceholder(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Divider(color: colorScheme.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Text(
            'Simplified Settlements',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Settlement breakdown will appear here when the trip is finished.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
