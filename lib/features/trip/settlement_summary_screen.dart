import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/settlement.dart';
import '../../core/models/trip.dart';
import '../../core/riverpod/balances_provider.dart';
import '../../core/riverpod/expenses_provider.dart';
import '../../core/riverpod/members_provider.dart';
import '../../core/riverpod/trip_provider.dart';
import '../../core/services/export_service.dart';
import '../../core/services/settlement_service.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/member_colors.dart';
import '../../ui_components/primary_button.dart';

/// Screen displayed when a host finishes a trip.
/// It renders summary stats, net balances, and peer transfers
/// calculated by the greedy simplified settlements algorithm.
class SettlementSummaryScreen extends ConsumerStatefulWidget {
  final String tripId;

  const SettlementSummaryScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<SettlementSummaryScreen> createState() =>
      _SettlementSummaryScreenState();
}

class _SettlementSummaryScreenState extends ConsumerState<SettlementSummaryScreen> {
  bool _isCopying = false;

  Future<void> _copySummaryToClipboard(Trip trip) async {
    setState(() => _isCopying = true);

    try {
      final exportService = ExportService();
      final text = await exportService.buildTripSummary(trip.id);
      
      await Clipboard.setData(ClipboardData(text: text));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Summary copied to clipboard! WhatsApp friendly 💸'),
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
        setState(() => _isCopying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripControllerProvider);
    final membersAsync = ref.watch(membersControllerProvider);
    final expensesAsync = ref.watch(expensesControllerProvider);
    final balances = ref.watch(balancesProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Summary'),
        automaticallyImplyLeading: false, // Force closure workflow
      ),
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load summary')),
        data: (trip) {
          if (trip == null) {
            return const Center(child: Text('No active trip found'));
          }

          final members = membersAsync.value ?? [];
          final expenses = expensesAsync.value ?? [];

          final memberMap = {for (final m in members) m.id: m.name};
          final memberIndexMap = {for (var i = 0; i < members.length; i++) members[i].id: i};

          final totalSpent = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
          final settlements = SettlementService.instance.calculateSettlements(balances);

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      // 🎉 Header card
                      Card(
                        elevation: 0,
                        color: colorScheme.primary.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          child: Column(
                            children: [
                              Text(
                                'Trip Complete! 🎉',
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                trip.title,
                                style: textTheme.titleLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatColumn('Members', '${members.length}', colorScheme),
                                  _buildStatColumn('Expenses', '${expenses.length}', colorScheme),
                                  _buildStatColumn('Total spent', formatPKR(totalSpent), colorScheme),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 🤝 Simplified Settlements Group
                      Text(
                        'Simplified Settlements',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Optimized to minimize transfers between members.',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                      ),
                      const SizedBox(height: 12),

                      if (settlements.isEmpty)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.1),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(Icons.celebration, size: 36, color: Colors.green),
                                SizedBox(height: 12),
                                Text(
                                  'Everyone is fully settled up!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: settlements.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final s = settlements[index];
                            return _buildSettlementRow(context, s, memberMap, memberIndexMap);
                          },
                        ),
                      const SizedBox(height: 24),

                      // 📊 Net Balances Group
                      Text(
                        'Final Balances',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: balances.entries.map((entry) {
                              final name = memberMap[entry.key] ?? 'Unknown';
                              final val = entry.value;
                              final isPositive = val >= 0;
                              final balanceColor = isPositive ? const Color(0xFF4ADE80) : const Color(0xFFFF6B6B);
                              final index = memberIndexMap[entry.key] ?? 0;
                              final avatarColor = getMemberColor(index);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: avatarColor.withValues(alpha: 0.15),
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: TextStyle(color: avatarColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    ),
                                    Text(
                                      val == 0 ? 'Settled' : (isPositive ? '+${formatPKR(val)}' : '-${formatPKR(val.abs())}'),
                                      style: TextStyle(
                                        color: val == 0 ? colorScheme.outline : balanceColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Action Drawer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.canvasColor,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _isCopying ? null : () => _copySummaryToClipboard(trip),
                          icon: const Icon(Icons.share),
                          label: Text(_isCopying ? 'Generating summary...' : 'Copy WhatsApp Summary'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colorScheme.secondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: PrimaryButton(
                          label: 'Back to Home Hub 🚗',
                          onPressed: () async {
                            await ref.read(tripControllerProvider.notifier).clearActiveTrip();
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementRow(
    BuildContext context,
    Settlement settlement,
    Map<String, String> memberMap,
    Map<String, int> memberIndexMap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final fromName = memberMap[settlement.fromId] ?? 'Unknown';
    final toName = memberMap[settlement.toId] ?? 'Unknown';

    final fromIdx = memberIndexMap[settlement.fromId] ?? 0;
    final toIdx = memberIndexMap[settlement.toId] ?? 0;

    final fromColor = getMemberColor(fromIdx);
    final toColor = getMemberColor(toIdx);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Debtor (Ower)
            CircleAvatar(
              radius: 16,
              backgroundColor: fromColor.withValues(alpha: 0.15),
              child: Text(
                fromName.isNotEmpty ? fromName[0].toUpperCase() : '?',
                style: TextStyle(color: fromColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fromName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Transfer Arrow + Amount
            Column(
              children: [
                Text(
                  formatPKR(settlement.amount),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.trending_flat,
                  color: colorScheme.secondary,
                  size: 20,
                ),
              ],
            ),

            // Creditor (Recipient)
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                toName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              backgroundColor: toColor.withValues(alpha: 0.15),
              child: Text(
                toName.isNotEmpty ? toName[0].toUpperCase() : '?',
                style: TextStyle(color: toColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
