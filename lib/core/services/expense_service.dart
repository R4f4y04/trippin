import '../models/expense.dart';
import '../models/split_type.dart';
import '../models/user.dart';
import '../utils/app_logger.dart';

class ExpenseService {
  Map<String, double> calculateNetBalances({
    required List<User> members,
    required List<Expense> expenses,
  }) {
    final balances = <String, double>{
      for (final member in members) member.id: 0,
    };

    for (final expense in expenses) {
      if (expense.beneficiaryIds.isEmpty) {
        AppLogger.warning('Expense ${expense.id} has no beneficiaries');
        continue;
      }

      switch (expense.splitType) {
        case SplitType.equal:
          _applyEqualSplit(expense, balances);
      }
    }

    return balances;
  }

  void _applyEqualSplit(Expense expense, Map<String, double> balances) {
    final count = expense.beneficiaryIds.length;
    if (count == 0) return;

    final share = expense.amount / count;

    balances.update(
      expense.payerId,
      (value) => value + expense.amount,
      ifAbsent: () => expense.amount,
    );

    for (final beneficiaryId in expense.beneficiaryIds) {
      balances.update(
        beneficiaryId,
        (value) => value - share,
        ifAbsent: () => -share,
      );
    }
  }
}
