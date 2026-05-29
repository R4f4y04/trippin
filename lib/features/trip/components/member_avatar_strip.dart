import 'package:flutter/material.dart';

import '../../../core/models/user.dart';
import '../../../core/utils/member_colors.dart';

import '../../../core/utils/animations.dart';
import '../../../core/utils/haptics.dart';

/// Horizontal scrollable strip of member avatars with an "Add" button at the end.
///
/// Each avatar is a circle showing the member's initial in their assigned color.
/// The host sees a "+ Add" button at the trailing edge.
class MemberAvatarStrip extends StatelessWidget {
  final List<User> members;
  final bool showAddButton;
  final VoidCallback? onAddPressed;

  const MemberAvatarStrip({
    super.key,
    required this.members,
    this.showAddButton = false,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: members.length + (showAddButton ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == members.length) {
            return _buildAddButton(context);
          }
          return PopIn(
            duration: Duration(milliseconds: 400 + (index < 6 ? index * 60 : 0)), // Staggered pop-in for members
            child: _buildAvatar(context, index, members[index]),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, int index, User member) {
    final color = getMemberColor(index);
    final initial = member.name.isNotEmpty
        ? member.name[0].toUpperCase()
        : '?';

    return Tooltip(
      message: member.name,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: color.withValues(alpha: 0.2),
        child: Text(
          initial,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        AppHaptics.lightTap();
        onAddPressed?.call();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.add,
          color: colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }
}
