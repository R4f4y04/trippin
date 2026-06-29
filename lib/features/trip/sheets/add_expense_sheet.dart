import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/trip.dart';
import '../../../core/models/user.dart';
import '../../../core/models/connection_state.dart';
import '../../../core/riverpod/connection_provider.dart';
import '../../../core/riverpod/expenses_provider.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/member_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../../ui_components/primary_button.dart';
import '../components/member_chip.dart';

/// Full-screen/draggable bottom sheet for adding a new expense.
class AddExpenseSheet extends ConsumerStatefulWidget {
  final Trip trip;
  final List<User> members;

  const AddExpenseSheet({
    super.key,
    required this.trip,
    required this.members,
  });

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  String? _payerId;
  final Set<String> _selectedBeneficiaries = {};
  bool _isNoteExpanded = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Default payer to device owner, else first member
    final owner = widget.members.where((m) => m.isDeviceOwner).toList();
    _payerId = owner.isNotEmpty ? owner.first.id : (widget.members.isNotEmpty ? widget.members.first.id : null);
    
    // Default beneficiaries to all members
    _selectedBeneficiaries.addAll(widget.members.map((m) => m.id));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _currentAmount {
    return double.tryParse(_amountController.text) ?? 0.0;
  }

  double get _splitAmount {
    if (_selectedBeneficiaries.isEmpty) return 0.0;
    return _currentAmount / _selectedBeneficiaries.length;
  }

  void _toggleAllBeneficiaries() {
    AppHaptics.lightTap();
    setState(() {
      if (_selectedBeneficiaries.length == widget.members.length) {
        _selectedBeneficiaries.clear();
      } else {
        _selectedBeneficiaries.clear();
        _selectedBeneficiaries.addAll(widget.members.map((m) => m.id));
      }
    });
  }

  Future<void> _saveExpense() async {
    final name = _descriptionController.text.trim();
    if (name.isEmpty) {
      _showSnack('What was this expense for? (e.g. "Dinner")');
      return;
    }

    final amount = _currentAmount;
    if (amount <= 0) {
      _showSnack('Please enter a valid amount');
      return;
    }

    if (_payerId == null) {
      _showSnack('Please select who paid');
      return;
    }

    if (_selectedBeneficiaries.isEmpty) {
      _showSnack('Select at least one beneficiary to split with');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(expensesControllerProvider.notifier).addExpense(
            tripId: widget.trip.id,
            payerId: _payerId!,
            amount: amount,
            beneficiaryIds: _selectedBeneficiaries.toList(),
            name: name,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );

      if (mounted) {
        AppHaptics.successBuzz();
        Navigator.of(context).pop();
        _showSnack('Expense saved');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to save expense');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final connectionState = ref.watch(connectionControllerProvider);
    final isGuest = connectionState.role == ConnectionRole.guest ||
        widget.trip.deviceRole == 'guest';

    final deviceOwner = widget.members.where((m) => m.isDeviceOwner).toList();
    final payers = (isGuest && deviceOwner.isNotEmpty)
        ? deviceOwner
        : widget.members;

    return Container(
      decoration: BoxDecoration(
        color: theme.canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Text(
                'New Expense',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Large amount input area
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₨',
                      style: textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IntrinsicWidth(
                      child: TextField(
                        controller: _amountController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // "What was it for?"
              TextField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What was it for?',
                  hintText: 'e.g. Dinner, Fuel, Airbnb',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  prefixIcon: Icon(Icons.receipt_long),
                ),
              ),
              const SizedBox(height: 20),

              // "Who paid?" section
              Text(
                'Who Paid?',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: payers.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final member = payers[index];
                    final colorIndex = widget.members.indexWhere((m) => m.id == member.id);
                    final color = getMemberColor(colorIndex >= 0 ? colorIndex : index);
                    final isSelected = _payerId == member.id;
                    return MemberChip(
                      name: member.name,
                      memberColor: color,
                      isSelected: isSelected,
                      onTap: isGuest
                          ? () {} // Lock tap interactions for guests
                          : () {
                              AppHaptics.lightTap();
                              setState(() => _payerId = member.id);
                            },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // "Split between" section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Split Between',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleAllBeneficiaries,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      _selectedBeneficiaries.length == widget.members.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: TextStyle(color: colorScheme.secondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.members.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final member = widget.members[index];
                    final color = getMemberColor(index);
                    final isSelected = _selectedBeneficiaries.contains(member.id);
                    return MemberChip(
                      name: member.name,
                      memberColor: color,
                      isSelected: isSelected,
                      onTap: () {
                        AppHaptics.lightTap();
                        setState(() {
                          if (isSelected) {
                            _selectedBeneficiaries.remove(member.id);
                          } else {
                            _selectedBeneficiaries.add(member.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Note Collapsible Section
              GestureDetector(
                onTap: () => setState(() => _isNoteExpanded = !_isNoteExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        _isNoteExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: colorScheme.outline,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isNoteExpanded ? 'Hide Note' : 'Add Note (Optional)',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isNoteExpanded) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Add notes or details',
                    hintText: 'e.g. Saad paid for coffee too',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // Live split card
              if (_currentAmount > 0 && _selectedBeneficiaries.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Each person owes:',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      Text(
                        formatPKR(_splitAmount),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Save Button
              SizedBox(
                height: 52,
                child: PrimaryButton(
                  label: 'Save Expense',
                  isLoading: _isSaving,
                  onPressed: _saveExpense,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
