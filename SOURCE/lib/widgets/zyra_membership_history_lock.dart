import 'package:flutter/material.dart';

import '../screens/subscription/upgrade_screen.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// A visible membership boundary, not an empty list or a purchase action.
/// The Upgrade route only opens the existing honest membership information.
class ZyraMembershipHistoryLock extends StatelessWidget {
  final String description;

  const ZyraMembershipHistoryLock({super.key, required this.description});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, size: 19, color: ZyraColors.ink(0.65)),
            const SizedBox(width: 10),
            Expanded(child: Text(description, style: ZyraText.subtext())),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const UpgradeScreen()),
          ),
          child: const Text('Upgrade'),
        ),
        const SizedBox(height: 6),
        Text(
          'View membership information. Purchases are not available yet.',
          style: ZyraText.subtext(size: 11.5),
        ),
      ],
    ),
  );
}
