import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/expense.dart';
import '../../core/models/connection_state.dart';
import '../../core/models/trip.dart';
import '../../core/models/user.dart';
import '../../core/riverpod/balances_provider.dart';
import '../../core/riverpod/connection_provider.dart';
import '../../core/riverpod/expense_sync_status_provider.dart';
import '../../core/riverpod/expenses_provider.dart';
import '../../core/riverpod/members_provider.dart';
import '../../core/riverpod/sync_queue_provider.dart';
import '../../core/riverpod/trip_list_provider.dart';
import '../../core/riverpod/trip_provider.dart';
import '../../ui_components/primary_button.dart';
import '../connection/connect_screen.dart';
import 'components/balances_list.dart';
import 'components/closed_banner.dart';
import 'components/connection_status_banner.dart';
import 'components/error_state.dart';
import 'components/expenses_list.dart';
import 'components/members_list.dart';
import 'components/section_card.dart';
import 'components/trip_summary_card.dart';

class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key});

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripControllerProvider);
    final membersAsync = ref.watch(membersControllerProvider);
    final expensesAsync = ref.watch(expensesControllerProvider);
    final balances = ref.watch(balancesProvider);
    final syncStatuses = ref.watch(expenseSyncStatusProvider);
    final connectionState = ref.watch(connectionControllerProvider);
    final queuedCountAsync = ref.watch(syncQueueCountProvider);

    return tripAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: ErrorState(message: 'Failed to load trip', onRetry: _refreshAll),
      ),
      data: (trip) {
        if (trip == null) {
          return const Scaffold(body: Center(child: Text('No active trip')));
        }

        if (membersAsync.hasError || expensesAsync.hasError) {
          return Scaffold(
            body: ErrorState(
              message: 'Failed to load trip data',
              onRetry: _refreshAll,
            ),
          );
        }

        final members = membersAsync.value ?? [];
        final expenses = expensesAsync.value ?? [];
        final isClosed = trip.isClosed;
        final isGuestRole = connectionState.role == ConnectionRole.guest;
        final memberMap = {
          for (final member in members) member.id: member.name,
        };

        final isLoading = membersAsync.isLoading || expensesAsync.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Active Trip'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: _refreshAll,
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (isClosed) ...[
                        ClosedBanner(
                          onReopen: isGuestRole
                              ? () => _showSnack(
                                  'Guest mode cannot reopen trip in this phase',
                                )
                              : () => _confirmReopenTrip(trip),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TripSummaryCard(trip: trip, memberCount: members.length),
                      const SizedBox(height: 12),
                      ConnectionStatusBanner(
                        connectionState: connectionState,
                        queuedCount: queuedCountAsync.valueOrNull,
                        hasUnsyncedItems: syncStatuses.values.any(
                          (status) => status != ExpenseSyncStatus.synced,
                        ),
                        canAddConnectedGuest:
                            connectionState.role == ConnectionRole.host &&
                            connectionState.isConnected &&
                            connectionState.selectedDevice != null &&
                            !isClosed,
                        onManageConnection: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ConnectScreen(),
                          ),
                        ),
                        onAddConnectedGuest: () => _addConnectedGuestAsMember(
                          trip,
                          members,
                          connectionState.selectedDevice?.displayName ?? '',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SectionCard(
                        title: 'Members',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MembersList(members: members),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: 'Add Member',
                              onPressed: isClosed || isGuestRole
                                  ? null
                                  : () => _showAddMemberDialog(trip, members),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SectionCard(
                        title: 'Expenses',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExpensesList(
                              expenses: expenses,
                              memberMap: memberMap,
                              isReadOnly: isClosed || isGuestRole,
                              syncStatuses: syncStatuses,
                              onEdit: (expense) => _showEditExpenseDialog(
                                trip,
                                members,
                                expense,
                              ),
                              onDelete: _confirmDeleteExpense,
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: 'Add Expense',
                              onPressed: isClosed
                                  ? null
                                  : () => _showAddExpenseDialog(trip, members),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SectionCard(
                        title: 'Balances',
                        child: BalancesList(
                          balances: balances,
                          memberMap: memberMap,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SectionCard(
                        title: 'Trip Actions',
                        child: PrimaryButton(
                          label: isClosed ? 'Trip Finished' : 'Finish Trip',
                          onPressed: isClosed || isGuestRole
                              ? null
                              : () => _confirmCloseTrip(trip),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<void> _refreshAll() async {
    await ref.read(tripControllerProvider.notifier).refresh();
    await ref.read(membersControllerProvider.notifier).refresh();
    await ref.read(expensesControllerProvider.notifier).refresh();
    await ref.read(syncQueueCountProvider.notifier).refresh();
  }

  Future<void> _showAddMemberDialog(Trip trip, List<User> members) async {
    final connectionState = ref.read(connectionControllerProvider);
    if (connectionState.role == ConnectionRole.guest) {
      _showSnack('Guest mode cannot add members in this phase');
      return;
    }

    final nameController = TextEditingController();
    final owner = members.where((user) => user.isDeviceOwner).toList();
    if (owner.isEmpty) {
      _showSnack('Device owner not found');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
                onPressed: () => Navigator.of(dialogContext).pop(),
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
                  if (trip.isClosed) {
                    _showSnack('Trip is closed');
                    return;
                  }
                  setState(() => isSaving = true);
                  final success = await ref
                      .read(membersControllerProvider.notifier)
                      .addMember(
                        tripId: trip.id,
                        name: name,
                        managedBy: owner.first.id,
                      );
                  if (dialogContext.mounted) {
                    setState(() => isSaving = false);
                    if (success) {
                      Navigator.of(dialogContext).pop();
                    }
                  }
                  if (mounted) {
                    _showSnack(
                      success ? 'Member added' : 'Failed to add member',
                    );
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
                    decoration: const InputDecoration(
                      labelText: 'Expense Name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                    ),
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
                  await ref
                      .read(expensesControllerProvider.notifier)
                      .addExpense(
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

  Future<void> _confirmCloseTrip(Trip trip) async {
    final connectionState = ref.read(connectionControllerProvider);
    if (connectionState.role == ConnectionRole.guest) {
      _showSnack('Guest mode cannot finish trip in this phase');
      return;
    }

    final pendingCount = ref
        .read(expenseSyncStatusProvider)
        .values
        .where((status) => status != ExpenseSyncStatus.synced)
        .length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finish Trip'),
        content: Text(
          pendingCount > 0
              ? 'There are $pendingCount unsynced item(s). Finishing now may leave other devices behind. Continue?'
              : 'This will make the trip read-only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tripControllerProvider.notifier).closeTrip(trip.id);
      await ref.read(membersControllerProvider.notifier).refresh();
      await ref.read(expensesControllerProvider.notifier).refresh();
      await ref.read(tripListControllerProvider.notifier).refresh();
      _showSnack('Trip finished');
    }
  }

  Future<void> _addConnectedGuestAsMember(
    Trip trip,
    List<User> members,
    String guestName,
  ) async {
    if (trip.isClosed) {
      _showSnack('Trip is closed');
      return;
    }

    final normalizedGuestName = guestName.trim();
    if (normalizedGuestName.isEmpty) {
      _showSnack('Connected guest name is unavailable');
      return;
    }

    final alreadyExists = members.any(
      (member) =>
          member.name.trim().toLowerCase() == normalizedGuestName.toLowerCase(),
    );
    if (alreadyExists) {
      _showSnack('Connected guest already exists in members');
      return;
    }

    final owner = members.where((user) => user.isDeviceOwner).toList();
    if (owner.isEmpty) {
      _showSnack('Device owner not found');
      return;
    }

    final success = await ref
        .read(membersControllerProvider.notifier)
        .addMember(
          tripId: trip.id,
          name: normalizedGuestName,
          managedBy: owner.first.id,
        );
    _showSnack(
      success
          ? 'Connected guest added as member'
          : 'Failed to add connected guest',
    );
  }

  Future<void> _confirmReopenTrip(Trip trip) async {
    final connectionState = ref.read(connectionControllerProvider);
    if (connectionState.role == ConnectionRole.guest) {
      _showSnack('Guest mode cannot reopen trip in this phase');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reopen Trip'),
        content: const Text('This will allow editing again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reopen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tripControllerProvider.notifier).reopenTrip(trip.id);
      _showSnack('Trip reopened');
    }
  }

  Future<void> _showEditExpenseDialog(
    Trip trip,
    List<User> members,
    Expense expense,
  ) async {
    final connectionState = ref.read(connectionControllerProvider);
    if (connectionState.role == ConnectionRole.guest) {
      _showSnack('Guest mode cannot edit expenses in this phase');
      return;
    }

    final nameController = TextEditingController(text: expense.name);
    final amountController = TextEditingController(
      text: expense.amount.toString(),
    );
    final noteController = TextEditingController(text: expense.note ?? '');
    String? payerId = expense.payerId;
    final selectedBeneficiaries = <String>{...expense.beneficiaryIds};

    await showDialog<void>(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Edit Expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                    ),
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
                  await ref
                      .read(expensesControllerProvider.notifier)
                      .updateExpense(
                        expenseId: expense.id,
                        name: expenseName,
                        amount: amount,
                        payerId: payerId!,
                        beneficiaryIds: selectedBeneficiaries.toList(),
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );
                  if (mounted) {
                    Navigator.of(context).pop();
                    _showSnack('Expense updated');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteExpense(Expense expense) async {
    final connectionState = ref.read(connectionControllerProvider);
    if (connectionState.role == ConnectionRole.guest) {
      _showSnack('Guest mode cannot delete expenses in this phase');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete ${expense.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(expensesControllerProvider.notifier)
          .deleteExpense(expenseId: expense.id);
      _showSnack('Expense deleted');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
