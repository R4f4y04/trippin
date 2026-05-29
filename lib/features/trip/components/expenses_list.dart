import 'package:flutter/material.dart';

import '../../../core/models/expense.dart';
import '../../../core/riverpod/expense_sync_status_provider.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/member_colors.dart';
import '../../../core/utils/animations.dart';
import '../../../core/utils/haptics.dart';

/// Redesigned expense list with styled cards featuring:
/// - Payer color bar on the left edge
/// - PKR formatted amounts
/// - Beneficiary color dots
/// - Relative timestamps
/// - Swipe-to-edit (right) and swipe-to-delete (left)
class ExpensesList extends StatelessWidget {
  final List<Expense> expenses;
  final Map<String, String> memberMap;

  /// Maps member ID → index in the trip's member list, for color assignment.
  final Map<String, int> memberIndexMap;
  final bool isReadOnly;
  final Map<String, ExpenseSyncStatus> syncStatuses;
  final ValueChanged<Expense> onEdit;
  final ValueChanged<Expense> onDelete;

  const ExpensesList({
    super.key,
    required this.expenses,
    required this.memberMap,
    required this.memberIndexMap,
    required this.isReadOnly,
    required this.syncStatuses,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long,
                size: 40,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No expenses yet. Tap + to log your first one.',
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

    // Reverse chronological order.
    final sorted = List<Expense>.from(expenses)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final expense = sorted[index];
        return FadeSlideIn(
          duration: Duration(milliseconds: 300 + (index < 5 ? index * 80 : 0)), // Staggered entry for first few items
          child: _buildExpenseCard(context, expense),
        );
      },
    );
  }

  Widget _buildExpenseCard(BuildContext context, Expense expense) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final payerIndex = memberIndexMap[expense.payerId] ?? 0;
    final payerColor = getMemberColor(payerIndex);
    final payerName = memberMap[expense.payerId] ?? 'Unknown';
    final syncStatus = syncStatuses[expense.id];

    final card = Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Payer color bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: payerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: name + amount
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expense.name,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatPKR(expense.amount),
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Middle row: payer + split + time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$payerName paid · ${_splitLabel(expense)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeAgo(expense.createdAt),
                          style: textTheme.bodySmall?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Bottom row: beneficiary dots + sync badge
                    Row(
                      children: [
                        // Beneficiary dots
                        ...expense.beneficiaryIds.take(8).map((id) {
                          final idx = memberIndexMap[id] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: getMemberColor(idx),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }),
                        if (expense.beneficiaryIds.length > 8)
                          Text(
                            '+${expense.beneficiaryIds.length - 8}',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),

                        const Spacer(),

                        // Sync badge
                        if (syncStatus != null)
                          _buildSyncBadge(context, syncStatus),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isReadOnly) return card;

    // Swipe gestures: left to delete, right to edit
    return Dismissible(
      key: Key(expense.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          AppHaptics.warningBuzz();
          onDelete(expense);
        } else if (direction == DismissDirection.startToEnd) {
          AppHaptics.lightTap();
          onEdit(expense);
        }
        return false; // Don't auto-dismiss; callbacks handle it.
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.edit, color: Color(0xFF3B82F6)),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Color(0xFFFF6B6B)),
      ),
      child: card,
    );
  }

  String _splitLabel(Expense expense) {
    final count = expense.beneficiaryIds.length;
    final totalMembers = memberMap.length;
    if (count == totalMembers) return 'Everyone ($count)';
    return '$count people';
  }

  Widget _buildSyncBadge(BuildContext context, ExpenseSyncStatus status) {
    final (String label, Color color) = switch (status) {
      ExpenseSyncStatus.pending => ('Pending', const Color(0xFFFBBF24)),
      ExpenseSyncStatus.retrying => ('Queued', const Color(0xFFFBBF24)),
      ExpenseSyncStatus.synced => ('Synced', const Color(0xFF4ADE80)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
