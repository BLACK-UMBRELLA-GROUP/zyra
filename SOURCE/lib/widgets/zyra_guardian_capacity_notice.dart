import 'package:flutter/material.dart';

import '../data/zyra_guardian_capacity.dart';
import '../screens/subscription/upgrade_screen.dart';

/// Keeps limit feedback on the current page; account/link actions remain usable.
void showZyraGuardianCapacityNotice(BuildContext context, String? message) {
  if (!ZyraGuardianCapacity.isCapacityMessage(message)) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message!),
      action: message == ZyraGuardianCapacity.basicLimitMessage
          ? SnackBarAction(
              label: 'Upgrade',
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const UpgradeScreen())),
            )
          : null,
    ),
  );
}
