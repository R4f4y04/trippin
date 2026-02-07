import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../models/user.dart';
import '../services/expense_service.dart';
import 'expenses_provider.dart';
import 'members_provider.dart';

final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService();
});

final balancesProvider = Provider<Map<String, double>>((ref) {
  final membersValue = ref.watch(membersControllerProvider);
  final expensesValue = ref.watch(expensesControllerProvider);
  final members = membersValue.maybeWhen(
    data: (data) => data,
    orElse: () => <User>[],
  );
  final expenses = expensesValue.maybeWhen(
    data: (data) => data,
    orElse: () => <Expense>[],
  );

  return ref.read(expenseServiceProvider).calculateNetBalances(
        members: members,
        expenses: expenses,
      );
});
