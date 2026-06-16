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
import '../../core/riverpod/trip_history_provider.dart';
import '../../core/riverpod/trip_list_provider.dart';
import '../../core/riverpod/trip_provider.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/animations.dart';
import '../../core/utils/haptics.dart';
import '../about/about_screen.dart';
import '../history/trip_history_screen.dart';
import '../settings/settings_screen.dart';
import '../connection/host_lobby_screen.dart';
import 'components/activity_timeline.dart';
import 'components/add_member_options_sheet.dart';
import 'components/balances_list.dart';
import 'components/closed_banner.dart';
import 'components/connection_status_banner.dart';
import 'components/error_state.dart';
import 'components/expenses_list.dart';
import 'components/member_avatar_strip.dart';
import 'components/trip_header.dart';
import 'components/trip_nav_drawer.dart';
import 'sheets/add_expense_sheet.dart';
import 'sheets/add_member_sheet.dart';
import 'sheets/edit_expense_sheet.dart';
import 'settlement_summary_screen.dart';

class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key});

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {}); // Rebuild to hide/show FAB depending on tab
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Trip?>>(tripControllerProvider, (previous, next) {
      final prevTrip = previous?.valueOrNull;
      final nextTrip = next.valueOrNull;
      if (prevTrip != null && nextTrip != null) {
        if (!prevTrip.isClosed && nextTrip.isClosed) {
          // Transition both host and guest seamlessly when trip finishes
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => SettlementSummaryScreen(tripId: nextTrip.id),
            ),
          );
        }
      }
    });

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
        final isHost = !isGuestRole;
        final memberMap = {
          for (final member in members) member.id: member.name,
        };
        final memberIndexMap = {
          for (var i = 0; i < members.length; i++) members[i].id: i,
        };
        final canAddConnectedGuest =
            connectionState.role == ConnectionRole.host &&
            connectionState.isConnected &&
            connectionState.selectedDevice != null &&
            !isClosed;

        final isLoading = membersAsync.isLoading || expensesAsync.isLoading;

        // Calculate totals for the header.
        final totalSpent = expenses.fold<double>(
          0.0,
          (sum, e) => sum + e.amount,
        );
        final owner = members.where((m) => m.isDeviceOwner).toList();
        final personalBalance = owner.isNotEmpty
            ? (balances[owner.first.id] ?? 0.0)
            : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: Text(trip.title, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: _refreshAll,
              ),
            ],
          ),
          drawer: TripNavDrawer(
            trip: trip,
            isHost: isHost,
            isClosed: isClosed,
            onOpenHistory: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TripHistoryScreen()),
            ),
            onOpenSettings: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            onOpenAbout: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
            onFinishTrip: () => _confirmCloseTrip(trip),
          ),

          // FAB — visible only on Expenses tab (index 0) when trip is active.
          floatingActionButton: (isClosed || _tabController.index != 0)
              ? null
              : PulsingGlow(
                  glowColor: Theme.of(context).colorScheme.primary,
                  maxRadius: 4.0,
                  child: FloatingActionButton(
                    onPressed: () {
                      AppHaptics.lightTap();
                      _showAddExpenseSheet(trip, members);
                    },
                    child: const Icon(Icons.add),
                  ),
                ),

          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // — Closed banner —
                    if (isClosed)
                      ClosedBanner(
                        onReopen: isGuestRole
                            ? () => _showSnack('Guest mode cannot reopen trip')
                            : () => _confirmReopenTrip(trip),
                      ),

                    // — Connection status strip —
                    ConnectionStatusBanner(
                      connectionState: connectionState,
                      queuedCount: queuedCountAsync.valueOrNull,
                      hasUnsyncedItems: syncStatuses.values.any(
                        (status) => status != ExpenseSyncStatus.synced,
                      ),
                      canAddConnectedGuest: canAddConnectedGuest,
                      onManageConnection: () {
                        if (isHost) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HostLobbyScreen(),
                            ),
                          );
                        } else {
                          ref
                              .read(connectionControllerProvider.notifier)
                              .startGuestScan();
                          _showSnack('Re-scanning for host...');
                        }
                      },
                      onAddConnectedGuest: () => _addConnectedGuestAsMember(
                        trip,
                        members,
                        connectionState.selectedDevice?.displayName ?? '',
                      ),
                    ),

                    // — Trip header —
                    TripHeader(
                      trip: trip,
                      memberCount: members.length,
                      totalSpent: totalSpent,
                      personalBalance: personalBalance,
                    ),

                    const SizedBox(height: 4),

                    // — Member avatar strip —
                    MemberAvatarStrip(
                      members: members,
                      showAddButton: isHost && !isClosed,
                      onAddPressed: () => _showAddMemberOptions(
                        trip,
                        members,
                        canAddConnectedGuest,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // — Tab bar —
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Expenses'),
                        Tab(text: 'Balances'),
                        Tab(text: 'Activity'),
                      ],
                    ),

                    // — Tab content —
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 0: Expenses
                          ExpensesList(
                            expenses: expenses,
                            memberMap: memberMap,
                            memberIndexMap: memberIndexMap,
                            isReadOnly: isClosed || isGuestRole,
                            syncStatuses: syncStatuses,
                            onEdit: (expense) =>
                                _showEditExpenseSheet(trip, members, expense),
                            onDelete: _confirmDeleteExpense,
                          ),

                          // Tab 1: Balances
                          BalancesList(
                            balances: balances,
                            memberMap: memberMap,
                            memberIndexMap: memberIndexMap,
                          ),

                          // Tab 2: Activity
                          _buildActivityTab(trip),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildActivityTab(Trip trip) {
    final historyAsync = ref.watch(tripHistoryControllerProvider(trip.id));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Failed to load activity')),
      data: (events) => ActivityTimeline(events: events),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Action methods (preserved from original)
  // ─────────────────────────────────────────────────────────

  Future<void> _refreshAll() async {
    await ref.read(tripControllerProvider.notifier).refresh();
    await ref.read(membersControllerProvider.notifier).refresh();
    await ref.read(expensesControllerProvider.notifier).refresh();
    await ref.read(syncQueueCountProvider.notifier).refresh();
  }

  Future<void> _showAddMemberSheet(Trip trip, List<User> members) async {
    final connectionState = ref.read(connectionControllerProvider);
    if (connectionState.role == ConnectionRole.guest) {
      _showSnack('Guest mode cannot add members');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMemberSheet(trip: trip, members: members),
    );
  }

  Future<void> _showAddMemberOptions(
    Trip trip,
    List<User> members,
    bool canAddConnectedGuest,
  ) async {
    if (trip.isClosed) {
      _showSnack('Trip is closed');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => AddMemberOptionsSheet(
        canConnectGuest: canAddConnectedGuest,
        onAddLocalMember: () {
          Navigator.of(sheetContext).pop();
          _showAddMemberSheet(trip, members);
        },
        onConnectGuest: () {
          final guestName =
              ref
                  .read(connectionControllerProvider)
                  .selectedDevice
                  ?.displayName ??
              '';
          Navigator.of(sheetContext).pop();
          _addConnectedGuestAsMember(trip, members, guestName);
        },
      ),
    );
  }

  Future<void> _showAddExpenseSheet(Trip trip, List<User> members) async {
    if (members.isEmpty) {
      _showSnack('Add members before logging expenses');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseSheet(trip: trip, members: members),
    );
  }

  Future<void> _confirmCloseTrip(Trip trip) async {
    final connectionState = ref.read(connectionControllerProvider);
    if (connectionState.role == ConnectionRole.guest) {
      _showSnack('Guest mode cannot finish trip');
      return;
    }

    final pendingCount = ref
        .read(expenseSyncStatusProvider)
        .values
        .where((status) => status != ExpenseSyncStatus.synced)
        .length;

    AppHaptics.warningBuzz();
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
      // Broadcast end trip protocol to all connected guests
      final connectionState = ref.read(connectionControllerProvider);
      if (connectionState.isConnected) {
        await SyncService.instance.sendFinishTrip(tripId: trip.id);
      }

      await ref.read(tripControllerProvider.notifier).closeTrip(trip.id);
      await ref.read(membersControllerProvider.notifier).refresh();
      await ref.read(expensesControllerProvider.notifier).refresh();
      await ref.read(tripListControllerProvider.notifier).refresh();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SettlementSummaryScreen(tripId: trip.id),
        ),
      );
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
      _showSnack('Guest mode cannot reopen trip');
      return;
    }

    AppHaptics.warningBuzz();
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
      AppHaptics.successBuzz();
      _showSnack('Trip reopened');
    }
  }

  Future<void> _showEditExpenseSheet(
    Trip trip,
    List<User> members,
    Expense expense,
  ) async {
    final connectionState = ref.read(connectionControllerProvider);
    if (connectionState.role == ConnectionRole.guest) {
      _showSnack('Guest mode cannot edit expenses');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditExpenseSheet(
        trip: trip,
        members: members,
        expense: expense,
      ),
    );
  }

  Future<void> _confirmDeleteExpense(Expense expense) async {
    final connectionState = ref.read(connectionControllerProvider);
    if (connectionState.role == ConnectionRole.guest) {
      _showSnack('Guest mode cannot delete expenses');
      return;
    }

    AppHaptics.warningBuzz();
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
