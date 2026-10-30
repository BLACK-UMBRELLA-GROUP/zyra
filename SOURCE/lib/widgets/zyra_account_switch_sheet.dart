import 'zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

enum ZyraAccountContext { seeker, guardian }

/// Product boundary for one login that owns both ZYRA experiences.
///
/// Identity and account security are deliberately shared. Everything that
/// can change independently between Seeker and Guardian stays in its own
/// context, including the paid plan. This is display guidance only; server
/// authorisation must continue to come from owned rows and Guardian links.
class ZyraAccountContextPolicy {
  ZyraAccountContextPolicy._();

  static const sharedSummary =
      'One login · identity check and security stay shared';
  static const separateSummary =
      'Profiles, activity and memberships stay separate';
}

class ZyraAccountSwitchOption {
  final ZyraAccountContext context;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool current;
  final bool enabled;
  final String? actionLabel;

  const ZyraAccountSwitchOption({
    required this.context,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.current = false,
    this.enabled = true,
    this.actionLabel,
  });

  /// A current context is informational, never a second navigation action.
  bool get selectable => enabled && !current;

  String get resolvedActionLabel {
    if (current) return 'CURRENT';
    return actionLabel ?? (enabled ? 'SWITCH ›' : 'UNAVAILABLE');
  }
}

/// Opens the shared full-screen account-context picker.
///
/// This deliberately returns a selection rather than performing navigation.
/// The caller owns the current shell and decides whether a selection opens a
/// completed context or its first-time onboarding.
Future<ZyraAccountContext?> showZyraAccountSwitchPage({
  required BuildContext context,
  required List<ZyraAccountSwitchOption> options,
}) {
  return Navigator.of(context).push<ZyraAccountContext>(
    MaterialPageRoute(
      builder: (_) => ZyraAccountSwitchScreen(options: options),
    ),
  );
}

class ZyraAccountSwitchScreen extends StatelessWidget {
  final List<ZyraAccountSwitchOption> options;

  const ZyraAccountSwitchScreen({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    key: const ValueKey('switch-account-back'),
                    tooltip: 'Back',
                    onPressed: ZyraTapFeedback.onTap(
                      context,
                      () => Navigator.of(context).pop(),
                    ),
                    icon: Icon(Icons.chevron_left, color: ZyraColors.ink(0.70)),
                  ),
                  Expanded(
                    child: Text(
                      'Switch Account',
                      textAlign: TextAlign.center,
                      style: ZyraText.heading(size: 17),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              SizedBox(height: 42),
              Text(
                'CHOOSE YOUR ACCOUNT',
                style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
              ),
              SizedBox(height: 10),
              Text(
                'Move between your Seeker and Guardian experiences without signing out.',
                style: ZyraText.subtext(size: 13),
              ),
              SizedBox(height: 26),
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AccountOption(
                    option: option,
                    onTap: option.selectable
                        ? () => Navigator.of(context).pop(option.context)
                        : null,
                  ),
                ),
              SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ZyraColors.surfaceFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ZyraColors.surfaceBorder,
                    width: 0.6,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 18,
                          color: ZyraColors.unlockText,
                        ),
                        SizedBox(width: 9),
                        Text(
                          'ONE TRUSTED IDENTITY',
                          style: ZyraText.chapterLabel(
                            color: ZyraColors.unlockText,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      ZyraAccountContextPolicy.sharedSummary,
                      style: ZyraText.subtext(
                        size: 11.5,
                        color: ZyraColors.ink(0.56),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      ZyraAccountContextPolicy.separateSummary,
                      style: ZyraText.subtext(
                        size: 11.5,
                        color: ZyraColors.ink(0.46),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact, explicit entry point used in both Profile headers.
class ZyraAccountSwitchButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ZyraAccountSwitchButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Switch Account',
      child: OutlinedButton.icon(
        key: const ValueKey('switch-account-button'),
        onPressed: ZyraTapFeedback.onTap(context, onPressed),
        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
        label: Text('Switch', style: ZyraText.subtext(size: 11.5)),
        style: OutlinedButton.styleFrom(
          foregroundColor: ZyraColors.foreground,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: ZyraColors.ink(0.22), width: 0.7),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

class _AccountOption extends StatelessWidget {
  final ZyraAccountSwitchOption option;
  final VoidCallback? onTap;

  const _AccountOption({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final contentOpacity = option.enabled ? 1.0 : 0.46;
    final action = option.resolvedActionLabel;

    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: option.current,
      label: '${option.title}. ${option.subtitle}. $action',
      child: Material(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: ZyraTapFeedback.onTap(context, onTap),
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: contentOpacity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: option.current
                      ? ZyraColors.accentBorder
                      : ZyraColors.surfaceBorder,
                  width: option.current ? 0.9 : 0.6,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ZyraColors.iconButtonBg,
                      border: Border.all(
                        color: option.current
                            ? ZyraColors.unlockDot
                            : ZyraColors.iconButtonBorder,
                      ),
                    ),
                    child: Icon(
                      option.icon,
                      size: 19,
                      color: option.current
                          ? ZyraColors.unlockText
                          : ZyraColors.ink(0.70),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option.title, style: ZyraText.body(size: 14)),
                        SizedBox(height: 3),
                        Text(
                          option.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ZyraText.subtext(
                            size: 10.5,
                            color: ZyraColors.ink(0.38),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    action,
                    style: ZyraText.chapterLabel(
                      color: option.current || option.enabled
                          ? ZyraColors.unlockText
                          : ZyraColors.ink(0.30),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
