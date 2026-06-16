import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/trip.dart';
import '../../../core/models/user.dart';
import '../../../core/riverpod/members_provider.dart';
import '../../../ui_components/primary_button.dart';

/// Full-screen/draggable bottom sheet for adding a new member locally.
class AddMemberSheet extends ConsumerStatefulWidget {
  final Trip trip;
  final List<User> members;

  const AddMemberSheet({
    super.key,
    required this.trip,
    required this.members,
  });

  @override
  ConsumerState<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<AddMemberSheet> {
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveMember() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Member name is required');
      return;
    }

    final owner = widget.members.where((user) => user.isDeviceOwner).toList();
    if (owner.isEmpty) {
      _showSnack('Device owner not found');
      return;
    }

    if (widget.trip.isClosed) {
      _showSnack('Trip is closed');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final success = await ref
          .read(membersControllerProvider.notifier)
          .addMember(
            tripId: widget.trip.id,
            name: name,
            managedBy: owner.first.id,
          );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          _showSnack('Member added');
        } else {
          _showSnack('Failed to add member');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('An error occurred');
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
                'Add Member',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Member Name Field
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Member Name',
                  hintText: 'e.g. Saad, Ali, Fatima',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  prefixIcon: Icon(Icons.person_add),
                ),
                onSubmitted: (_) => _saveMember(),
              ),
              const SizedBox(height: 28),

              // Save Button
              SizedBox(
                height: 52,
                child: PrimaryButton(
                  label: 'Add Member',
                  isLoading: _isSaving,
                  onPressed: _saveMember,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
