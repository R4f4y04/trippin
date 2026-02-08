import '../models/expense.dart';
import '../models/trip.dart';
import '../models/trip_history_event.dart';
import '../models/user.dart';
import 'expense_service.dart';
import 'storage_service.dart';

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
    final history = await _storage.getTripHistory(trip.id);

    final memberMap = {for (final m in members) m.id: m.name};
    final totalAmount = _calculateTotal(expenses);
    final balances = _expenseService.calculateNetBalances(
      members: members,
      expenses: expenses,
    );

    final buffer = StringBuffer();
    buffer.writeln('Trip: ${trip.title}');
    buffer.writeln('Status: ${trip.isClosed ? 'Closed' : 'Open'}');
    buffer.writeln('Created: ${trip.createdAt}');
    if (trip.closedAt != null) {
      buffer.writeln('Closed: ${trip.closedAt}');
    }
    buffer.writeln('Members: ${members.length}');
    buffer.writeln('Total: PKR ${totalAmount.toStringAsFixed(2)}');
    buffer.writeln('');

    buffer.writeln('Balances:');
    final balanceEntries = balances.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in balanceEntries) {
      buffer.writeln(
        '- ${memberMap[entry.key] ?? 'Unknown'}: ${entry.value.toStringAsFixed(2)}',
      );
    }
    buffer.writeln('');

    buffer.writeln('Expenses:');
    for (final expense in expenses) {
      buffer.writeln(
        '- ${expense.name}: PKR ${expense.amount.toStringAsFixed(2)} | Paid by ${memberMap[expense.payerId] ?? 'Unknown'}',
      );
    }
    buffer.writeln('');

    buffer.writeln('History:');
    for (final event in history.reversed) {
      buffer.writeln('- ${event.createdAt}: ${event.summary}');
    }

    return buffer.toString();
  }

  double _calculateTotal(List<Expense> expenses) {
    return expenses.fold(0, (sum, expense) => sum + expense.amount);
  }
}
