import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_email_templates.dart';

/// LOCK 39 em90. The caller owns sample values; toggling does not request
/// device permission, change a live account, or send email.
class ZyraEmailSettingsPreview extends StatelessWidget {
  const ZyraEmailSettingsPreview({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final ZyraPreviewEmailSettings settings;
  final void Function(ZyraEmailSetting setting, bool enabled) onChanged;

  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey('zyra_email_settings_preview'),
    color: ZyraColors.ivoryTop,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ZyraColors.ivoryTop, ZyraColors.ivoryBottom],
        ),
      ),
      child: SafeArea(
        child: ListView(
          key: const ValueKey('zyra_email_settings_scroll'),
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 36),
          physics: const ScrollPhysics(),
          children: [
            Text('Notifications & emails', style: ZyraText.pageTitle()),
            const SizedBox(height: 49),
            _sectionLabel('ON YOUR PHONE'),
            const SizedBox(height: 12),
            _card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _switchRow(
                      'Journey requests',
                      ZyraEmailSetting.journeyRequests,
                    ),
                    _switchRow(
                      'Journey stages and updates',
                      ZyraEmailSetting.journeyStages,
                    ),
                    _switchRow('Messages', ZyraEmailSetting.messages),
                    _switchRow(
                      'Guardian activity',
                      ZyraEmailSetting.guardianActivity,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 35),
            _sectionLabel('EMAILS'),
            const SizedBox(height: 12),
            _card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: [
                    _switchRow(
                      'Journey emails',
                      ZyraEmailSetting.journeyEmails,
                      detail: 'New Journey requests and Journeys that begin',
                    ),
                    _fixedRow(
                      'Membership reminders',
                      'Before a free trial ends and before renewals',
                    ),
                    _fixedRow(
                      'Account and safety',
                      'Sign-up, identity check, reports, your data, closing your account',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Membership reminders and account and safety emails are always sent, because the law or your safety needs them.',
              style: ZyraText.body(
                size: 12.5,
                color: ZyraColors.secondaryText,
              ).copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _card({required Widget child}) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xD9FAF5EC),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x0F3E2E1E)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F3E2E1E),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );

  Widget _sectionLabel(String label) => Text(
    label,
    style: ZyraText.body(
      size: 9.5,
      color: ZyraColors.secondaryText,
    ).copyWith(letterSpacing: 1.4),
  );

  Widget _switchRow(String label, ZyraEmailSetting setting, {String? detail}) =>
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 51),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: ZyraText.body(
                        size: 15,
                        color: ZyraColors.espresso,
                      ),
                    ),
                    if (detail != null)
                      Text(
                        detail,
                        style: ZyraText.body(
                          size: 12,
                          color: ZyraColors.secondaryText,
                        ).copyWith(height: 1.35),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: label,
                toggled: settings.value(setting),
                onTap: () => onChanged(setting, !settings.value(setting)),
                child: GestureDetector(
                  key: ValueKey('email_setting_${setting.name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(setting, !settings.value(setting)),
                  child: Container(
                    width: 46,
                    height: 28,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: settings.value(setting)
                          ? ZyraColors.goldTextFill
                          : const Color(0x2E3E2E1E),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Align(
                      alignment: settings.value(setting)
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: ZyraColors.ivoryTop,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0x33000000), blurRadius: 3),
                          ],
                        ),
                        child: SizedBox(width: 22, height: 22),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _fixedRow(String label, String detail) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 51),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ZyraText.body(size: 15)),
                Text(
                  detail,
                  style: ZyraText.body(
                    size: 12,
                    color: ZyraColors.secondaryText,
                  ).copyWith(height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Always on',
            style: ZyraText.body(size: 13, color: ZyraColors.secondaryText),
          ),
        ],
      ),
    ),
  );
}
