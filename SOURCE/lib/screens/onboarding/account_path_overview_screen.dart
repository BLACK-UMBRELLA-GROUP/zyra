import 'package:flutter/material.dart';

import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../wali/wali_onboarding_flow.dart';
import 'chapter2_flow.dart';

/// A calm orientation screen before a long onboarding path begins.
///
/// Founder-approved direction, 2026-08-19: signup chooses which experience
/// to begin with, but one trusted identity can later carry both the Seeker
/// and Guardian experiences. This screen explains the chosen path without
/// presenting it as a permanent account-type decision.
class SeekerOnboardingOverviewScreen extends StatelessWidget {
  final String? gender;
  final bool migrationGatedPreview;

  const SeekerOnboardingOverviewScreen({
    super.key,
    required this.gender,
    this.migrationGatedPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return _AccountPathOverview(
      eyebrow: 'YOUR MARRIAGE PROFILE',
      title: 'Here’s what we’ll build together.',
      description:
          'Your progress saves as you go. Leave at any time and return to '
          'the next unfinished question.',
      items: const [
        _OverviewItem(
          number: '01',
          title: 'About You',
          description: 'Identity and essential details',
          state: 'Done',
          complete: true,
        ),
        _OverviewItem(
          number: '02',
          title: 'Your Profile',
          description: 'Photos and background',
          state: 'Next',
          active: true,
        ),
        _OverviewItem(
          number: '03',
          title: 'Your Bio',
          description: 'Optional · Journey-only sharing',
          state: 'Optional',
        ),
        _OverviewItem(
          number: '04',
          title: 'Your Values',
          description: 'Private compatibility answers',
          state: 'Save & return',
        ),
        _OverviewItem(
          number: '05',
          title: 'Your Preferences',
          description: 'Traffic-light matching choices',
          state: 'Save & return',
        ),
        _OverviewItem(
          number: '06',
          title: 'Ready',
          description: 'Review before going live',
          state: 'Review',
        ),
      ],
      buttonLabel: migrationGatedPreview
          ? 'Seeker Setup Ready'
          : 'Continue to Your Profile',
      onContinue: () {
        if (migrationGatedPreview) {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: ZyraColors.luxuryDarkPurple,
              title: Text(
                'Ready for activation',
                style: ZyraText.heading(size: 18),
              ),
              content: Text(
                'The Seeker setup is ready. Activating it for an existing '
                'Guardian requires the approved account-context migration, '
                'which has not been run.',
                style: ZyraText.subtext(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Understood', style: ZyraText.button()),
                ),
              ],
            ),
          );
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Chapter2Flow(gender: gender)),
        );
      },
    );
  }
}

class GuardianOnboardingOverviewScreen extends StatelessWidget {
  /// True when this is opened from an existing Seeker account during the
  /// migration-gated preview. The screen can be reviewed end to end, but it
  /// must not call the current create-Wali RPC: that RPC permanently assigns
  /// one role and would reject or corrupt a dual-context account.
  final bool migrationGatedPreview;

  const GuardianOnboardingOverviewScreen({
    super.key,
    this.migrationGatedPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return _AccountPathOverview(
      eyebrow: 'GUARDIAN ACCOUNT',
      title: 'Prepare to support someone you care for.',
      description:
          'We begin with your trusted identity, then collect only the details '
          'needed for the Guardian experience.',
      items: const [
        _OverviewItem(
          number: '01',
          title: 'Your Identity',
          description: 'Name and age verification',
          state: 'Required',
          active: true,
        ),
        _OverviewItem(
          number: '02',
          title: 'Your Relationship',
          description: 'How you support your Seeker',
          state: 'Required',
        ),
        _OverviewItem(
          number: '03',
          title: 'Guardian Presentation',
          description: 'Photo and Guardian bio',
          state: 'Next phase',
        ),
        _OverviewItem(
          number: '04',
          title: 'Responsibilities',
          description: 'Guidance, privacy and consent',
          state: 'Required',
        ),
      ],
      note:
          'If you later add a Seeker account, your trusted identity stays '
          'shared. You will not create another login.',
      buttonLabel: migrationGatedPreview
          ? 'Guardian Setup Ready'
          : 'Begin Guardian Setup',
      onContinue: () {
        if (migrationGatedPreview) {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: ZyraColors.luxuryDarkPurple,
              title: Text(
                'Ready for activation',
                style: ZyraText.heading(size: 18),
              ),
              content: Text(
                'The Guardian setup is ready. Activating it for an existing '
                'Seeker requires the approved account-context migration, '
                'which has not been run.',
                style: ZyraText.subtext(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Understood', style: ZyraText.button()),
                ),
              ],
            ),
          );
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WaliOnboardingFlow()),
        );
      },
    );
  }
}

class _AccountPathOverview extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final List<_OverviewItem> items;
  final String? note;
  final String buttonLabel;
  final VoidCallback onContinue;

  const _AccountPathOverview({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.items,
    required this.buttonLabel,
    required this.onContinue,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Colors.white70,
                            ),
                          ),
                          const Spacer(),
                          Text('ZYRA', style: ZyraText.wordmark(size: 18)),
                        ],
                      ),
                      const SizedBox(height: 34),
                      Text(
                        eyebrow,
                        style: ZyraText.chapterLabel(color: Colors.white54),
                      ),
                      const SizedBox(height: 10),
                      Text(title, style: ZyraText.heading(size: 27)),
                      const SizedBox(height: 10),
                      Text(description, style: ZyraText.subtext(size: 13.5)),
                      const SizedBox(height: 24),
                      for (final item in items) ...[
                        _OverviewRow(item: item),
                        const SizedBox(height: 9),
                      ],
                      if (note != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border(
                              left: BorderSide(
                                color: ZyraColors.unlockDot,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            note!,
                            style: ZyraText.subtext(size: 11.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: onContinue,
                    child: Text(buttonLabel, style: ZyraText.button()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewItem {
  final String number;
  final String title;
  final String description;
  final String state;
  final bool active;
  final bool complete;

  const _OverviewItem({
    required this.number,
    required this.title,
    required this.description,
    required this.state,
    this.active = false,
    this.complete = false,
  });
}

class _OverviewRow extends StatelessWidget {
  final _OverviewItem item;

  const _OverviewRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final accent = item.complete
        ? ZyraColors.publicText
        : item.active
        ? ZyraColors.unlockText
        : Colors.white30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: ZyraColors.frostFill,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ZyraColors.frostBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
              border: Border.all(color: accent.withValues(alpha: 0.75)),
            ),
            child: item.complete
                ? Icon(Icons.check, color: accent, size: 15)
                : Text(
                    item.number,
                    style: ZyraText.chapterLabel(color: accent),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: ZyraText.body(size: 14)),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: ZyraText.subtext(size: 10.5, color: Colors.white38),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(item.state, style: ZyraText.subtext(size: 10, color: accent)),
        ],
      ),
    );
  }
}
