import 'package:flutter/material.dart';

import '../../../core/models/user.dart';

class MembersList extends StatelessWidget {
  final List<User> members;

  const MembersList({super.key, required this.members});

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
