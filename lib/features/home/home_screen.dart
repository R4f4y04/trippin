import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/expense.dart';
import '../../core/models/trip.dart';
import '../../core/models/user.dart';
import '../../core/riverpod/balances_provider.dart';
import '../../core/riverpod/expenses_provider.dart';
import '../../core/riverpod/members_provider.dart';
import '../../core/riverpod/trip_provider.dart';
import '../../ui_components/primary_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripControllerProvider);
    final membersAsync = ref.watch(membersControllerProvider);
    final expensesAsync = ref.watch(expensesControllerProvider);
    final balances = ref.watch(balancesProvider);

    final members = membersAsync.value ?? [];
    final expenses = expensesAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trippin'),
        actions: [
          if (tripAsync.value != null)
            IconButton(
              tooltip: 'Add Member',
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () => _showAddMemberDialog(tripAsync.value!, members),
            ),
          if (tripAsync.value != null)
            IconButton(
              tooltip: 'Add Expense',
              icon: const Icon(Icons.add_card),
              onPressed: () => _showAddExpenseDialog(tripAsync.value!, members),
            ),
        ],
      ),
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: 'Failed to load trip',
          onRetry: () => ref.read(tripControllerProvider.notifier).refresh(),
        ),
        data: (trip) {
          if (trip == null) {
            return _EmptyTripState(onCreateTrip: _showCreateTripDialog);
          }

          final memberMap = {
            for (final member in members) member.id: member.name,
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TripSummaryCard(trip: trip, memberCount: members.length),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Members',
                child: _MembersList(members: members),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Expenses',
                child: _ExpensesList(
                  expenses: expenses,
                  memberMap: memberMap,
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Net Balances',
                child: _BalancesList(
                  balances: balances,
                  memberMap: memberMap,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCreateTripDialog() async {
    final titleController = TextEditingController();
    final ownerController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Create Trip'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Trip Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerController,
                  decoration:
                      const InputDecoration(labelText: 'Your Name (Owner)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              PrimaryButton(
                label: 'Create',
                isLoading: isSaving,
                onPressed: () async {
                  final title = titleController.text.trim();
                  final ownerName = ownerController.text.trim();
                  if (title.isEmpty || ownerName.isEmpty) {
                    _showSnack('Title and owner name are required');
                    return;
                  }
                  setState(() => isSaving = true);
                  await ref.read(tripControllerProvider.notifier).createTrip(
                        title: title,
                        ownerName: ownerName,
                      );
                  await ref.read(membersControllerProvider.notifier).refresh();
                  await ref.read(expensesControllerProvider.notifier).refresh();
                  if (mounted) {
                    Navigator.of(context).pop();
                    _showSnack('Trip created');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddMemberDialog(Trip trip, List<User> members) async {
    final nameController = TextEditingController();
    final owner = members.where((user) => user.isDeviceOwner).toList();
    if (owner.isEmpty) {
      _showSnack('Device owner not found');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add Member'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Member Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              PrimaryButton(
                label: 'Add',
                isLoading: isSaving,
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    _showSnack('Member name is required');
                    return;
                  }
                  setState(() => isSaving = true);
                  await ref.read(membersControllerProvider.notifier).addMember(
                        tripId: trip.id,
                        name: name,
                        managedBy: owner.first.id,
                      );
                  if (mounted) {
                    Navigator.of(context).pop();
                    _showSnack('Member added');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddExpenseDialog(Trip trip, List<User> members) async {
    if (members.isEmpty) {
      _showSnack('Add members before logging expenses');
      return;
    }

    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String? payerId = members.first.id;
    final selectedBeneficiaries = <String>{...members.map((m) => m.id)};

    await showDialog<void>(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add Expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Expense Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: payerId,
                    decoration: const InputDecoration(labelText: 'Payer'),
                    items: members
                        .map(
                          (member) => DropdownMenuItem(
                            value: member.id,
                            child: Text(member.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => payerId = value),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Beneficiaries',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  ...members.map(
                    (member) => CheckboxListTile(
                      value: selectedBeneficiaries.contains(member.id),
                      title: Text(member.name),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedBeneficiaries.add(member.id);
                          } else {
                            selectedBeneficiaries.remove(member.id);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Note (Optional)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              PrimaryButton(
                label: 'Save',
                isLoading: isSaving,
                onPressed: () async {
                  final expenseName = nameController.text.trim();
                  if (expenseName.isEmpty) {
                    _showSnack('Expense name is required');
                    return;
                  }
                  final amountText = amountController.text.trim();
                  final amount = double.tryParse(amountText) ?? 0;
                  if (amount <= 0 || payerId == null) {
                    _showSnack('Enter a valid amount and payer');
                    return;
                  }
                  if (selectedBeneficiaries.isEmpty) {
                    _showSnack('Select at least one beneficiary');
                    return;
                  }
                  setState(() => isSaving = true);
                  await ref.read(expensesControllerProvider.notifier).addExpense(
                        tripId: trip.id,
                        payerId: payerId!,
                        amount: amount,
                        beneficiaryIds: selectedBeneficiaries.toList(),
                    name: expenseName,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );
                  if (mounted) {
                    Navigator.of(context).pop();
                    _showSnack('Expense added');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _TripSummaryCard extends StatelessWidget {
  final Trip trip;
  final int memberCount;

  const _TripSummaryCard({
    required this.trip,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Join Code: ${trip.joinCode}'),
            const SizedBox(height: 4),
            Text('Members: $memberCount'),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

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

class _MembersList extends StatelessWidget {
  final List<User> members;

  const _MembersList({required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Text('No members yet');
    }

    return Column(
      children: members
          .map(
            (member) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                member.isDeviceOwner ? Icons.phone_iphone : Icons.person,
              ),
              title: Text(member.name),
              subtitle: member.managedBy != null
                  ? Text('Managed by ${member.managedBy}')
                  : const Text('Device owner'),
            ),
          )
          .toList(),
    );
  }
}

class _ExpensesList extends StatelessWidget {
  final List<Expense> expenses;
  final Map<String, String> memberMap;

  const _ExpensesList({
    required this.expenses,
    required this.memberMap,
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

class _BalancesList extends StatelessWidget {
  final Map<String, double> balances;
  final Map<String, String> memberMap;

  const _BalancesList({
    required this.balances,
    required this.memberMap,
  });

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return const Text('No balances yet');
    }

    final entries = balances.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

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

class _EmptyTripState extends StatelessWidget {
  final VoidCallback onCreateTrip;

  const _EmptyTripState({required this.onCreateTrip});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create your first trip to start splitting expenses offline.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Create Trip', onPressed: onCreateTrip),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
