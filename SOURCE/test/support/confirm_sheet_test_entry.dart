import 'package:flutter/material.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/widgets/zyra_confirm_sheet.dart';

class ConfirmSheetTestEntry extends StatelessWidget {
  const ConfirmSheetTestEntry({
    super.key,
    required this.onDecision,
    this.hapticLevel,
  });

  final ValueChanged<bool?> onDecision;
  final ZyraHapticLevel? hapticLevel;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () async {
      final result = await showZyraConfirm(
        context: context,
        title: 'Hide Sara?',
        body:
            'Sara won’t appear in your Profiles again. You can show her again from Settings → Hidden Profiles.',
        primaryLabel: 'Hide profile',
        secondaryLabel: 'Keep profile',
        personName: 'Sara',
        primaryKey: const ValueKey('browse-hide-confirm'),
        secondaryKey: const ValueKey('browse-hide-cancel'),
        hapticLevel: hapticLevel == null ? null : () => hapticLevel!,
      );
      onDecision(result);
    },
    child: const Text('Open confirmation'),
  );
}
