import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/expense.dart';
import '../../core/models/trip_history_event.dart';
import '../../core/riverpod/trip_detail_provider.dart';
import '../../core/services/export_service.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(tripDetailProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          IconButton(
            tooltip: 'Export',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _showExport(context),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed: $error')),
        data: (detail) {
          final memberMap = {
            for (final member in detail.members) member.id: member.name,
          };
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(detail: detail, memberMap: memberMap),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Balances',
                child: _BalancesList(
                  balances: detail.balances,
                  memberMap: memberMap,
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Expenses',
                child: _ExpensesList(
                  expenses: detail.expenses,
                  memberMap: memberMap,
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'History',
                child: _HistoryList(history: detail.history),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showExport(BuildContext context) async {
    final exportText = await ExportService().buildTripSummary(tripId);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Trip Summary'),
        content: SingleChildScrollView(
          child: SelectableText(exportText),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: exportText));
              Navigator.of(context).pop();
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final TripDetail detail;
  final Map<String, String> memberMap;

  const _SummaryCard({required this.detail, required this.memberMap});

  @override
  Widget build(BuildContext context) {
    final total = detail.expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(detail.trip.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Status: ${detail.trip.isClosed ? 'Closed' : 'Open'}'),
            Text('Members: ${detail.members.length}'),
            Text('Total: PKR ${total.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _BalancesList extends StatelessWidget {
  final Map<String, double> balances;
  final Map<String, String> memberMap;

  const _BalancesList({required this.balances, required this.memberMap});

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return const Text('No balances yet');
    }
    final entries = balances.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: entries
          .map(
            (entry) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(memberMap[entry.key] ?? 'Unknown'),
              trailing: Text(
                entry.value.toStringAsFixed(2),
                style: TextStyle(
                  color: entry.value >= 0
                      ? Colors.greenAccent
                      : Colors.redAccent,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ExpensesList extends StatelessWidget {
  final List<Expense> expenses;
  final Map<String, String> memberMap;

  const _ExpensesList({required this.expenses, required this.memberMap});

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
              trailing: Text('PKR ${expense.amount.toStringAsFixed(2)}'),
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

class _HistoryList extends StatelessWidget {
  final List<TripHistoryEvent> history;

  const _HistoryList({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Text('No history yet');
    }

    return Column(
      children: history
          .map(
            (event) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(event.summary),
              subtitle: Text(event.createdAt.toString()),
            ),
          )
          .toList(),
    );
  }
}
