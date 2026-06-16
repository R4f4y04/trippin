import 'package:flutter/material.dart';

import '../../../core/models/settlement.dart';
import '../../../core/services/settlement_service.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/member_colors.dart';

/// Visual balance bars showing each member's net position,
/// followed by real-time optimized simplified peer settlements.
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

    final settlements = SettlementService.instance.calculateSettlements(balances);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: entries.length + 1, // +1 for settlement section
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == entries.length) {
          return _buildSettlementsSection(context, settlements);
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

  Widget _buildSettlementsSection(BuildContext context, List<Settlement> settlements) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: colorScheme.outline.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Text(
            'Simplified Settlements',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            settlements.isEmpty
                ? 'Everyone is fully settled up! 🎉'
                : '${settlements.length} transfer${settlements.length > 1 ? "s" : ""} to settle up.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 12),
          if (settlements.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: settlements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final s = settlements[index];
                return _buildSettlementRow(context, s);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSettlementRow(BuildContext context, Settlement settlement) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final fromName = memberMap[settlement.fromId] ?? 'Unknown';
    final toName = memberMap[settlement.toId] ?? 'Unknown';

    final fromIdx = memberIndexMap[settlement.fromId] ?? 0;
    final toIdx = memberIndexMap[settlement.toId] ?? 0;

    final fromColor = getMemberColor(fromIdx);
    final toColor = getMemberColor(toIdx);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Debtor Avatar + Name
          CircleAvatar(
            radius: 12,
            backgroundColor: fromColor.withValues(alpha: 0.15),
            child: Text(
              fromName.isNotEmpty ? fromName[0].toUpperCase() : '?',
              style: TextStyle(color: fromColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fromName,
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Arrow and Amount Transfer
          Column(
            children: [
              Text(
                formatPKR(settlement.amount),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Icon(
                Icons.trending_flat_rounded,
                color: colorScheme.secondary,
                size: 16,
              ),
            ],
          ),

          // Creditor Avatar + Name
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              toName,
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 12,
            backgroundColor: toColor.withValues(alpha: 0.15),
            child: Text(
              toName.isNotEmpty ? toName[0].toUpperCase() : '?',
              style: TextStyle(color: toColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
