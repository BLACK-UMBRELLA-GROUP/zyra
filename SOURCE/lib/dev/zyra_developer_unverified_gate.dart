// LOCK 34 §3.9, reused by the admin's local Unverified switch.
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/zyra_tab_title.dart';
import '../widgets/zyra_tap_feedback.dart';

class ZyraDeveloperUnverifiedGate extends StatelessWidget {
  const ZyraDeveloperUnverifiedGate({
    super.key,
    required this.guardian,
    required this.onVerify,
  });

  final bool guardian;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        ZyraNavBarMetrics.contentBottomClearance(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ZyraTabTitle(guardian ? 'Network' : 'Profiles'),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ZyraColors.goldText.withValues(alpha: .65),
                        ),
                      ),
                      child: Icon(
                        Icons.shield,
                        size: 34,
                        color: ZyraColors.goldText,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'VERIFIED MEMBERS ONLY',
                      textAlign: TextAlign.center,
                      style: ZyraText.chapterLabel(color: ZyraColors.goldText),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Every person on ZYRA is verified',
                      textAlign: TextAlign.center,
                      style: ZyraText.heading(size: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Verify your identity to see profiles, to be seen, '
                      'and to choose your membership. It takes about 2 minutes.',
                      textAlign: TextAlign.center,
                      style: ZyraText.body(
                        size: 14.5,
                        color: ZyraColors.mutedText,
                      ).copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          FilledButton(
            onPressed: ZyraTapFeedback.onTap(context, onVerify),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: ZyraColors.actionFill,
              foregroundColor: ZyraColors.espresso,
              side: BorderSide.none,
              shape: const StadiumBorder(),
            ),
            child: const Text('Verify now'),
          ),
        ],
      ),
    ),
  );
}
