import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/trip.dart';
import '../../core/riverpod/trip_detail_provider.dart';
import '../../core/riverpod/trip_list_provider.dart';
import '../../core/riverpod/trip_provider.dart';
import '../../core/services/export_service.dart';
import '../trip/components/activity_timeline.dart';
import '../trip/components/balances_list.dart';
import '../trip/components/expenses_list.dart';
import '../trip/components/trip_header.dart';

/// Redesigned Premium Read-Only Trip Detail Screen for History.
///
/// Features:
/// - Reuses the exact high-fidelity tabbed layout of the active TripScreen (Expenses / Balances / Activity)
/// - Deployed in read-only mode (No floating action button, no swipe edit/delete gestures)
/// - Overflow/AppBar actions: "Copy WhatsApp Summary" and "Reopen Trip" (restricted to host only)
class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportSummary(Trip trip) async {
    setState(() => _isExporting = true);

    try {
      final exportText = await ExportService().buildTripSummary(trip.id);
      await Clipboard.setData(ClipboardData(text: exportText));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp summary copied to clipboard! 📋✈️'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy summary.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _reopenTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reopen Trip'),
        content: Text('Would you like to reopen "${trip.title}"? This will set it as your active running trip.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reopen', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tripControllerProvider.notifier).reopenTrip(trip.id);
      await ref.read(tripListControllerProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip reopened! Welcome back 🚗'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Pop back to Home. AppShell will detect the reopened active trip and route to TripScreen automatically.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(tripDetailProvider(widget.tripId));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: detailAsync.when(
          loading: () => [],
          error: (_, __) => [],
          data: (detail) {
            final isHost = detail.trip.deviceRole == 'host';
            return [
              IconButton(
                tooltip: 'Copy Summary',
                icon: const Icon(Icons.share),
                onPressed: _isExporting ? null : () => _exportSummary(detail.trip),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'reopen') {
                    _reopenTrip(detail.trip);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'reopen',
                    enabled: isHost,
                    child: Row(
                      children: [
                        Icon(
                          Icons.restore,
                          color: isHost ? colorScheme.onSurface : colorScheme.outline,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('Reopen Trip'),
                      ],
                    ),
                  ),
                ],
              ),
            ];
          },
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.red),
                const SizedBox(height: 12),
                Text('Failed to load trip details', style: textTheme.titleMedium),
              ],
            ),
          ),
        ),
        data: (detail) {
          final members = detail.members;
          final expenses = detail.expenses;
          final balances = detail.balances;
          final history = detail.history;

          final memberMap = {for (final m in members) m.id: m.name};
          final memberIndexMap = {for (var i = 0; i < members.length; i++) members[i].id: i};

          final totalSpent = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
          final owner = members.where((m) => m.isDeviceOwner).toList();
          final personalBalance = owner.isNotEmpty ? (balances[owner.first.id] ?? 0.0) : 0.0;

          return Column(
            children: [
              // Proportional Trip Header details (same as TripScreen)
              TripHeader(
                trip: detail.trip,
                memberCount: members.length,
                totalSpent: totalSpent,
                personalBalance: personalBalance,
              ),
              const SizedBox(height: 12),

              // Custom tab bar styling
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Expenses'),
                  Tab(text: 'Balances'),
                  Tab(text: 'Activity'),
                ],
              ),

              // Tab views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 0: Expenses List in Read-only Mode
                    ExpensesList(
                      expenses: expenses,
                      memberMap: memberMap,
                      memberIndexMap: memberIndexMap,
                      isReadOnly: true, // Forces read-only rendering without gestures
                      syncStatuses: const {},
                      onEdit: (_) {},
                      onDelete: (_) {},
                    ),

                    // Tab 1: Balances View
                    BalancesList(
                      balances: balances,
                      memberMap: memberMap,
                      memberIndexMap: memberIndexMap,
                    ),

                    // Tab 2: Activity Timeline
                    ActivityTimeline(events: history),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
