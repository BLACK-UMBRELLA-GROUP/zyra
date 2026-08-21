import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

enum ZyraAccountContext { seeker, guardian }

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

/// The shared account-context picker for Seeker and Guardian surfaces.
///
/// This deliberately returns a selection rather than performing navigation.
/// The caller owns the current shell and decides whether a selection opens a
/// completed context or its first-time onboarding.
Future<ZyraAccountContext?> showZyraAccountSwitchSheet({
  required BuildContext context,
  required List<ZyraAccountSwitchOption> options,
}) {
  return showModalBottomSheet<ZyraAccountContext>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black38,
    builder: (sheetContext) => _AccountSwitchSheet(options: options),
  );
}

class _AccountSwitchSheet extends StatelessWidget {
  final List<ZyraAccountSwitchOption> options;

  const _AccountSwitchSheet({required this.options});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: ZyraColors.sheetGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Switch Account', style: ZyraText.heading(size: 22)),
              const SizedBox(height: 5),
              Text(
                'Choose which ZYRA experience you want to enter.',
                style: ZyraText.subtext(size: 12),
              ),
              const SizedBox(height: 16),
              for (final option in options)
                _AccountOption(
                  option: option,
                  onTap: option.selectable
                      ? () => Navigator.of(context).pop(option.context)
                      : null,
                ),
              const SizedBox(height: 11),
              Center(
                child: Text(
                  'No sign-out · your trusted identity remains shared',
                  textAlign: TextAlign.center,
                  style: ZyraText.subtext(size: 10, color: Colors.white38),
                ),
              ),
            ],
          ),
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
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Opacity(
            opacity: contentOpacity,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white12, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: option.current
                            ? ZyraColors.unlockDot
                            : Colors.white12,
                      ),
                    ),
                    child: Icon(
                      option.icon,
                      size: 19,
                      color: option.current
                          ? ZyraColors.unlockText
                          : Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option.title, style: ZyraText.body(size: 14)),
                        const SizedBox(height: 3),
                        Text(
                          option.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ZyraText.subtext(
                            size: 10.5,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    action,
                    style: ZyraText.chapterLabel(
                      color: option.current || option.enabled
                          ? ZyraColors.unlockText
                          : Colors.white30,
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
