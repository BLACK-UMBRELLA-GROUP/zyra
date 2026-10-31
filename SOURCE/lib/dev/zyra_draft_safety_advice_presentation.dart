// LOCK22 V5/V6: local Seeker and Guardian advice. Navigation and account authority stay in the host.
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';

class ZyraDraftSafetyAdvicePresentation extends StatelessWidget {
  const ZyraDraftSafetyAdvicePresentation({
    super.key,
    required this.onReport,
    required this.onHelp,
    required this.canAct,
    this.guardian = false,
  });

  final bool guardian;
  final VoidCallback onReport, onHelp;
  final bool Function() canAct;

  static const _tips = [
    (
      Icons.groups,
      'Keep your family close',
      'Your Main Guardian is part of every Journey. Talk to your Guardians before you meet anyone.',
    ),
    (
      Icons.place,
      'Meet safely',
      'Meet in a public place, with a Guardian or family member there. Tell someone where you are going.',
    ),
    (
      Icons.payments,
      'Never send money',
      'No one on ZYRA should ask you for money, gifts or bank details. If they do, report them.',
    ),
    (
      Icons.lock_outline,
      'Protect your details',
      'Keep your address, workplace and finances private until you have met the family and feel sure.',
    ),
    (
      Icons.visibility_off_outlined,
      'Trust how you feel',
      'If something feels wrong, you can end a Journey, hide or block at any time. They are not told why.',
    ),
  ];

  static const _guardianTips = [
    (
      Icons.groups,
      "Support, don't decide",
      'You are part of every Journey a Seeker you support begins. They choose whether to continue; share your view in the Guardian Circle.',
    ),
    (
      Icons.place,
      'Be there when they meet',
      'First meetings should be in a public place, with you or another family member present.',
    ),
    (
      Icons.payments,
      'Never send money',
      'No one on ZYRA should ask you or the Seeker for money, gifts or bank details. If they do, report them.',
    ),
    (
      Icons.lock_outline,
      'Protect family details',
      'Keep your home address, work and family finances private until both families have met and feel sure.',
    ),
    (
      Icons.outlined_flag,
      'Speak up early',
      'If something worries you, talk to the Seeker first, and report the profile if you need to.',
    ),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, bounds) {
        // Fit Guardian's longer copy above the home indicator by reclaiming
        // lower whitespace on short viewports. x07's spacing stays unchanged.
        final compact = guardian && bounds.maxHeight < 860;
        return ZyraShadowScrollView(
          key: const ValueKey('draft_safety_advice_scroll'),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Safety & advice', style: ZyraText.heading(size: 26)),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  key: const ValueKey('draft_safety_advice_monogram'),
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFA9792E).withValues(alpha: .7),
                    ),
                  ),
                  child: const ExcludeSemantics(
                    child: Icon(
                      Icons.health_and_safety,
                      color: ZyraColors.journeyGold,
                      size: 34,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                guardian
                    ? 'Support a safe Journey'
                    : 'Stay safe on your Journey',
                textAlign: TextAlign.center,
                style: ZyraText.heading(size: 26),
              ),
              const SizedBox(height: 4),
              Text(
                guardian ? 'ZYRA SAFETY · GUARDIANS' : 'ZYRA SAFETY',
                textAlign: TextAlign.center,
                style: ZyraText.body(
                  size: 11,
                  color: ZyraColors.goldText,
                ).copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              _card([
                for (final (icon, title, copy)
                    in (guardian ? _guardianTips : _tips))
                  _AdviceRow(icon: icon, title: title, copy: copy),
              ]),
              SizedBox(height: compact ? 8 : 16),
              _card([
                _AdviceRow(
                  key: const ValueKey('draft_safety_advice_report'),
                  icon: Icons.outlined_flag,
                  title: 'Report a profile',
                  copy: 'Open their profile and choose Report',
                  onTap: ZyraTapFeedback.onTap(
                    context,
                    onReport,
                    canAct: canAct,
                  ),
                ),
                _AdviceRow(
                  key: const ValueKey('draft_safety_advice_help'),
                  icon: Icons.help_outline,
                  title: 'Help & support',
                  onTap: ZyraTapFeedback.onTap(context, onHelp, canAct: canAct),
                ),
              ]),
              SizedBox(height: compact ? 6 : 14),
              Text(
                'In danger right now? Call your local emergency number (999 in the UK).',
                key: const ValueKey('draft_safety_advice_emergency'),
                textAlign: TextAlign.center,
                style: ZyraText.subtext(size: 12).copyWith(height: 1.4),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _card(List<Widget> rows) => ZyraFloatingSurface(
    radius: 20,
    child: Container(
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 54, right: 16),
                child: Divider(height: 1, color: ZyraColors.divider),
              ),
            rows[i],
          ],
        ],
      ),
    ),
  );
}

class _AdviceRow extends StatelessWidget {
  const _AdviceRow({
    super.key,
    required this.icon,
    required this.title,
    this.copy,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? copy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: copy == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 20, color: ZyraColors.journeyGold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ZyraText.body(size: 14)),
                if (copy != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    copy!,
                    style: ZyraText.subtext(size: 12).copyWith(height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: ZyraColors.ink(.28),
            ),
          ],
        ],
      ),
    );
    return MergeSemantics(
      child: onTap == null
          ? row
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: row,
            ),
    );
  }
}
