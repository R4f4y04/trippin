import '../models/expense.dart';
import '../utils/currency_format.dart';
import 'expense_service.dart';
import 'settlement_service.dart';
import 'storage_service.dart';

/// Service to format and export trip statistics and simplified settlements
/// in a WhatsApp-friendly format with emojis, bolding, and clean typography.
class ExportService {
  ExportService({StorageService? storage, ExpenseService? expenseService})
      : _storage = storage ?? StorageService.instance,
        _expenseService = expenseService ?? ExpenseService();

  final StorageService _storage;
  final ExpenseService _expenseService;

  Future<String> buildTripSummary(String tripId) async {
    final trip = await _storage.getTrip(tripId);
    if (trip == null) return 'Trip not found.';

    final members = await _storage.getUsersByIds(trip.memberIds);
    final expenses = await _storage.getExpensesByTrip(trip.id);

    final memberMap = {for (final m in members) m.id: m.name};
    final totalAmount = _calculateTotal(expenses);
    final balances = _expenseService.calculateNetBalances(
      members: members,
      expenses: expenses,
    );
    final settlements = SettlementService.instance.calculateSettlements(balances);

    final buffer = StringBuffer();
    buffer.writeln('*✈️ TRIP SUMMARY: ${trip.title.toUpperCase()}*');
    buffer.writeln('--------------------------------------------');
    buffer.writeln('📅 Status: ${trip.isClosed ? 'Completed ✅' : 'Active 🚀'}');
    buffer.writeln('👥 Members: ${members.length}');
    buffer.writeln('💰 Total Spent: *${formatPKR(totalAmount)}*');
    buffer.writeln('--------------------------------------------');
    buffer.writeln('');

    buffer.writeln('*📊 NET BALANCES:*');
    final balanceEntries = balances.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in balanceEntries) {
      final name = memberMap[entry.key] ?? 'Unknown';
      final val = entry.value;
      if (val.round() > 0) {
        buffer.writeln('🟢 $name: *Gets back ${formatPKR(val)}*');
      } else if (val.round() < 0) {
        buffer.writeln('🔴 $name: *Owes ${formatPKR(val.abs())}*');
      } else {
        buffer.writeln('⚪ $name: *Settled up*');
      }
    }
    buffer.writeln('');

    buffer.writeln('*🤝 SIMPLIFIED SETTLEMENTS:*');
    if (settlements.isEmpty) {
      buffer.writeln('🎉 Everyone is fully settled up!');
    } else {
      for (final s in settlements) {
        final from = memberMap[s.fromId] ?? 'Unknown';
        final to = memberMap[s.toId] ?? 'Unknown';
        buffer.writeln('💸 *● $from* owes *● $to*: *${formatPKR(s.amount)}*');
      }
    }
    buffer.writeln('');

    buffer.writeln('*📝 EXPENSES LIST:*');
    if (expenses.isEmpty) {
      buffer.writeln('No expenses recorded.');
    } else {
      final sortedExpenses = List<Expense>.from(expenses)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      for (final expense in sortedExpenses) {
        final paidBy = memberMap[expense.payerId] ?? 'Unknown';
        buffer.writeln('• *${expense.name}*: *${formatPKR(expense.amount)}* paid by $paidBy');
      }
    }

    buffer.writeln('');
    buffer.writeln('Shared via *Trippin* 🚗 Offline-first Expense Splitter.');
    return buffer.toString();
  }

  double _calculateTotal(List<Expense> expenses) {
    return expenses.fold(0, (sum, expense) => sum + expense.amount);
  }
}
