import 'package:flutter/material.dart';

import '../../../core/models/expense.dart';

class ExpensesList extends StatelessWidget {
  final List<Expense> expenses;
  final Map<String, String> memberMap;
  final bool isReadOnly;
  final ValueChanged<Expense> onEdit;
  final ValueChanged<Expense> onDelete;

  const ExpensesList({
    super.key,
    required this.expenses,
    required this.memberMap,
    required this.isReadOnly,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Text('No expenses logged');
    }

    return Column(
      children: expenses
          .map(
            (expense) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(expense.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('PKR ${expense.amount.toStringAsFixed(2)}'),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: isReadOnly ? null : () => onEdit(expense),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: isReadOnly ? null : () => onDelete(expense),
                  ),
                ],
              ),
              subtitle: Text(
                'Paid by ${memberMap[expense.payerId] ?? 'Unknown'} · '
                '${expense.beneficiaryIds.length} beneficiaries',
              ),
            ),
          )
          .toList(),
    );
  }
}
