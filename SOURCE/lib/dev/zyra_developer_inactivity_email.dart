// LOCK 32 email presentation only. No email delivery or account mutation.
import 'package:flutter/material.dart';

import '../widgets/zyra_wordmark.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_developer_title.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';

class ZyraDeveloperInactivityEmail extends StatelessWidget {
  const ZyraDeveloperInactivityEmail({
    super.key,
    required this.number,
    required this.endedCount,
    required this.firstName,
    required this.removalDate,
    required this.onOpen,
    required this.onBack,
  }) : assert(number >= 1 && number <= 5);

  final int number, endedCount;
  final String firstName;
  final DateTime removalDate;
  final VoidCallback? onOpen;
  final VoidCallback onBack;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get _date => '${removalDate.day} ${_months[removalDate.month - 1]}';
  String get _journeys =>
      '$endedCount Ended ${endedCount == 1 ? 'Journey' : 'Journeys'}';
  String get _subject => switch (number) {
    1 => 'We’ve missed you at ZYRA',
    2 => 'Your Ended Journeys: removal on $_date',
    3 => 'Your Ended Journeys will be removed on $_date',
    4 => '7 days left to keep your Ended Journeys',
    _ => 'Your Ended Journeys have been removed',
  };
  String get _chip => switch (number) {
    1 => 'Removal on $_date',
    2 => '3 weeks left',
    3 => '14 days left',
    4 => '7 days left · last reminder',
    _ => 'Removed today',
  };

  @override
  Widget build(BuildContext context) {
    final accent = number == 4
        ? ZyraColors.dangerText
        : number == 3
        ? ZyraColors.goldText
        : ZyraColors.mutedText;
    final readingAccent = number == 4
        ? ZyraColors.dangerTextStrong
        : number == 3
        ? ZyraColors.goldTextStrong
        : ZyraColors.secondaryStrong;
    Widget paragraph(String text, {bool muted = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: ZyraText.body(
          size: muted ? 12.5 : 14.5,
          color: muted ? ZyraColors.secondaryStrong : ZyraColors.espresso,
        ).copyWith(height: 1.55),
      ),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: ZyraTapFeedback.onTap(context, onBack),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Inbox'),
              ),
            ),
            ZyraDeveloperTitle(
              child: Text(
                _subject,
                style: ZyraText.heading(
                  size: 19,
                ).copyWith(fontWeight: FontWeight.w500, height: 1.3),
              ),
            ),
            const SizedBox(height: 12),
            ZyraFloatingSurface(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ZyraWordmark(
                      textAlign: TextAlign.center,
                      style: ZyraText.heading(
                        size: 26,
                      ).copyWith(color: ZyraColors.goldText, letterSpacing: 7),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          child: Text(
                            _chip,
                            style: ZyraText.body(
                              size: 12,
                              color: readingAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    paragraph('Assalaamu alaikum $firstName,'),
                    if (number == 5) ...[
                      paragraph(
                        'As ZYRA wasn’t opened for 2 years, we removed your $_journeys '
                        'today, with their Timelines and messages. This can’t be undone.',
                      ),
                      paragraph(
                        'Your profile, Guardians and membership are still here whenever you’re ready.',
                      ),
                    ] else ...[
                      paragraph(switch (number) {
                        1 || 2 => 'You haven’t opened ZYRA for almost 2 years.',
                        4 =>
                          'This is your last reminder. You haven’t opened ZYRA for 2 years.',
                        _ => 'You haven’t opened ZYRA for 2 years.',
                      }),
                      paragraph(
                        'To protect your privacy, we’ll remove your $_journeys, '
                        'with their Timelines and messages, on $_date ${removalDate.year}.',
                      ),
                      paragraph(
                        'Want to keep them? Just open ZYRA before then.',
                      ),
                    ],
                    FilledButton(
                      onPressed: ZyraTapFeedback.onTap(context, onOpen),
                      style: FilledButton.styleFrom(
                        backgroundColor: ZyraColors.goldTextFill,
                        foregroundColor: ZyraColors.espresso,
                        minimumSize: const Size.fromHeight(48),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Open ZYRA'),
                    ),
                    const SizedBox(height: 18),
                    if (number < 5)
                      paragraph(
                        'Your profile, Guardians and membership stay as they are.',
                        muted: true,
                      ),
                    paragraph(
                      'No longer using ZYRA? You can delete your account in '
                      'Settings → Advanced → Delete account.',
                      muted: true,
                    ),
                    paragraph('The ZYRA team', muted: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
