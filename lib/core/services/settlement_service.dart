import '../models/settlement.dart';

/// Service that computes simplified peer-to-peer settlements using a
/// greedy min-cash-flow algorithm (minimizing the number of transfers needed).
class SettlementService {
  SettlementService._();

  static final SettlementService instance = SettlementService._();

  /// Computes settlements.
  /// Receives a map of memberId -> netBalance (positive = creditor, negative = debtor).
  List<Settlement> calculateSettlements(Map<String, double> netBalances) {
    final settlements = <Settlement>[];

    // Separate into debtors (negative) and creditors (positive)
    final debtors = <_MemberBalance>[];
    final creditors = <_MemberBalance>[];

    netBalances.forEach((id, val) {
      // Round to avoid floating point precision issues (less than 1 PKR is ignored)
      final roundedVal = val.roundToDouble();
      if (roundedVal < 0) {
        debtors.add(_MemberBalance(id, roundedVal.abs()));
      } else if (roundedVal > 0) {
        creditors.add(_MemberBalance(id, roundedVal));
      }
    });

    // Sort by absolute balances descending to match largest debtors with largest creditors
    debtors.sort((a, b) => b.balance.compareTo(a.balance));
    creditors.sort((a, b) => b.balance.compareTo(a.balance));

    var debtorIdx = 0;
    var creditorIdx = 0;

    while (debtorIdx < debtors.length && creditorIdx < creditors.length) {
      final debtor = debtors[debtorIdx];
      final creditor = creditors[creditorIdx];

      final minAmount = debtor.balance < creditor.balance ? debtor.balance : creditor.balance;

      if (minAmount > 0) {
        settlements.add(
          Settlement(
            fromId: debtor.memberId,
            toId: creditor.memberId,
            amount: minAmount,
          ),
        );
      }

      debtor.balance -= minAmount;
      creditor.balance -= minAmount;

      if (debtor.balance.round() <= 0) {
        debtorIdx++;
      }
      if (creditor.balance.round() <= 0) {
        creditorIdx++;
      }
    }

    return settlements;
  }
}

class _MemberBalance {
  final String memberId;
  double balance;

  _MemberBalance(this.memberId, this.balance);
}
