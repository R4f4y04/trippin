/// Settlement model representing a transfer of money to settle debts.
class Settlement {
  final String fromId;
  final String toId;
  final double amount;

  const Settlement({
    required this.fromId,
    required this.toId,
    required this.amount,
  });
}
