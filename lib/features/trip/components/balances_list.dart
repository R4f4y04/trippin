import 'package:flutter/material.dart';

class BalancesList extends StatelessWidget {
  final Map<String, double> balances;
  final Map<String, String> memberMap;

  const BalancesList({
    super.key,
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
