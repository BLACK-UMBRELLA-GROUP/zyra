import 'package:flutter/material.dart';

import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

/// One concise contract for every Seeker onboarding stage.
///
/// The Founder-approved pattern is deliberately small: what comes next,
/// why ZYRA asks, who can see it, and whether it affects compatibility.
/// Keeping the copy here prevents individual chapter boundaries drifting.
class OnboardingStageContent {
  final String id;
  final String title;
  final String heading;
  final String summary;
  final String includes;
  final String visibility;
  final String outcome;
  final String buttonLabel;

  const OnboardingStageContent({
    required this.id,
    required this.title,
    required this.heading,
    required this.summary,
    required this.includes,
    required this.visibility,
    required this.outcome,
    required this.buttonLabel,
  });
}

enum SeekerOnboardingStage { buildProfile, journeyBio, compatibility, review }

const seekerOnboardingStages = <OnboardingStageContent>[
  OnboardingStageContent(
    id: 'build_profile',
    title: 'Your Profile',
    heading: 'First, the essentials.',
    summary: 'Build the profile people can discover and choose to match with.',
    includes: 'Your name, age, city, photos, faith and background details.',
    visibility:
        'Each question tells you whether it is public, private or revealed after a mutual match.',
    outcome: 'You will have a complete profile ready for ZYRA introductions.',
    buttonLabel: 'Start with Your Profile',
  ),
  OnboardingStageContent(
    id: 'journey_bio',
    title: 'Journey Bio',
    heading: 'Share the person behind the profile.',
    summary:
        'An optional space for your story and the life details you choose to share.',
    includes:
        'A personal Bio plus optional work, family and practical details.',
    visibility:
        'Shown only after a mutual match, inside your Journey. Never shown while browsing.',
    outcome:
        'A match can understand more about you when the Journey reaches Bio reveal.',
    buttonLabel: 'Build Your Journey Bio',
  ),
  OnboardingStageContent(
    id: 'compatibility',
    title: 'Compatibility',
    heading: 'Two parts. One considered result.',
    summary:
        'First tell ZYRA about yourself. Then set your partner preferences section by section.',
    includes:
        '104 About You questions, followed by 71 private partner preferences across the same 11 sections.',
    visibility: 'Private. Used to calculate your compatibility score.',
    outcome:
        'ZYRA can show where you align without revealing either person’s raw answers.',
    buttonLabel: 'Begin Compatibility',
  ),
  OnboardingStageContent(
    id: 'review',
    title: 'Review & Go Live',
    heading: 'Review, verify, go live.',
    summary: 'See your profile as others will and make any final changes.',
    includes: 'Your photos, profile, Journey Bio and compatibility settings.',
    visibility:
        'Verification details stay private. Others see only your approved profile.',
    outcome:
        'Your profile goes live only when you are ready and checks are complete.',
    buttonLabel: 'Review Everything',
  ),
];

class OnboardingStageIntroScreen extends StatefulWidget {
  final SeekerOnboardingStage stage;
  final VoidCallback onContinue;
  final String? welcomeName;

  const OnboardingStageIntroScreen({
    super.key,
    required this.stage,
    required this.onContinue,
    this.welcomeName,
  });

  @override
  State<OnboardingStageIntroScreen> createState() =>
      _OnboardingStageIntroScreenState();
}

class _OnboardingStageIntroScreenState
    extends State<OnboardingStageIntroScreen> {
  late final PageController _pageController = PageController();

  bool get _includesWelcome =>
      widget.stage == SeekerOnboardingStage.buildProfile;

  String? get _welcomeName {
    final value = widget.welcomeName?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> _showStage() => _pageController.animateToPage(
    1,
    duration: const Duration(milliseconds: 420),
    curve: Curves.easeInOutCubic,
  );

  Future<void> _showWelcome() => _pageController.animateToPage(
    0,
    duration: const Duration(milliseconds: 420),
    curve: Curves.easeInOutCubic,
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageIndex = widget.stage.index;
    final stage = seekerOnboardingStages[stageIndex];

    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: _includesWelcome
              ? PageView(
                  key: const ValueKey('onboarding_intro_page_view'),
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _WelcomePage(
                      firstName: _welcomeName,
                      onContinue: _showStage,
                    ),
                    _StagePage(
                      stage: stage,
                      stageIndex: stageIndex,
                      onScrollUp: _showWelcome,
                      onContinue: widget.onContinue,
                    ),
                  ],
                )
              : _StagePage(
                  stage: stage,
                  stageIndex: stageIndex,
                  onContinue: widget.onContinue,
                ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final String? firstName;
  final VoidCallback onContinue;

  const _WelcomePage({required this.firstName, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final greeting = firstName == null
        ? 'Welcome to ZYRA.'
        : 'Welcome to ZYRA, $firstName.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 20, 27, 22),
      child: Column(
        children: [
          Text('ZYRA', style: ZyraText.wordmark(size: 17)),
          const Spacer(flex: 2),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ZyraColors.frostFill,
              border: Border.all(
                color: ZyraColors.unlockDot.withValues(alpha: 0.62),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: ZyraColors.unlockText,
              size: 22,
            ),
          ),
          const SizedBox(height: 25),
          Text(
            greeting,
            key: const ValueKey('onboarding_welcome_title'),
            textAlign: TextAlign.center,
            style: ZyraText.heading(size: 29),
          ),
          const SizedBox(height: 12),
          Text(
            'Together, we’ll build four things.',
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 17),
          ),
          const SizedBox(height: 24),
          const _SignupRoadmap(),
          const Spacer(flex: 3),
          _JourneyContinueButton(
            key: const ValueKey('onboarding_welcome_continue'),
            label: 'Start with Your Profile',
            onTap: onContinue,
          ),
          const SizedBox(height: 13),
          const _PageDots(current: 0),
        ],
      ),
    );
  }
}

class _SignupRoadmap extends StatelessWidget {
  const _SignupRoadmap();

  static const _items = <(String, String)>[
    ('Your profile', 'The essentials and photos people see.'),
    ('Your Journey Bio', 'Shared only after a mutual match.'),
    ('Compatibility', 'Your answers and traffic lights together.'),
    ('Review & go live', 'Check everything before you are seen.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < _items.length; index++)
          _RoadmapRow(
            number: index + 1,
            title: _items[index].$1,
            note: _items[index].$2,
            showLine: index < _items.length - 1,
          ),
      ],
    );
  }
}

class _RoadmapRow extends StatelessWidget {
  final int number;
  final String title;
  final String note;
  final bool showLine;

  const _RoadmapRow({
    required this.number,
    required this.title,
    required this.note,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 49,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (showLine)
                  Positioned(
                    top: 25,
                    bottom: 0,
                    child: Container(width: 0.7, color: Colors.white24),
                  ),
                Container(
                  width: 27,
                  height: 27,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ZyraColors.unlockDot.withValues(alpha: 0.72),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '$number',
                    style: ZyraText.subtext(
                      size: 10.5,
                      color: ZyraColors.unlockText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ZyraText.body(size: 13.5)),
                  const SizedBox(height: 1),
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ZyraText.subtext(size: 10.5, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePage extends StatelessWidget {
  final OnboardingStageContent stage;
  final int stageIndex;
  final VoidCallback onContinue;
  final VoidCallback? onScrollUp;

  const _StagePage({
    required this.stage,
    required this.stageIndex,
    required this.onContinue,
    this.onScrollUp,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: const ValueKey('onboarding_stage_scrollable'),
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(27, 16, 27, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onScrollUp != null)
                    Align(
                      alignment: Alignment.center,
                      child: _ScrollUpCue(onTap: onScrollUp!),
                    )
                  else
                    const SizedBox(height: 25),
                  SizedBox(height: onScrollUp == null ? 20 : 23),
                  Row(
                    children: [
                      Text(
                        'YOUR SIGN-UP JOURNEY',
                        style: ZyraText.chapterLabel(color: Colors.white54),
                      ),
                      const Spacer(),
                      Text(
                        '${stageIndex + 1} OF ${seekerOnboardingStages.length}',
                        style: ZyraText.chapterLabel(color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (stageIndex + 1) / seekerOnboardingStages.length,
                      minHeight: 1.5,
                      backgroundColor: ZyraColors.progressTrack,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        ZyraColors.unlockDot,
                      ),
                    ),
                  ),
                  const SizedBox(height: 42),
                  Text(
                    stage.title.toUpperCase(),
                    style: ZyraText.chapterLabel(color: ZyraColors.unlockText),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    stage.heading,
                    key: ValueKey('onboarding_stage_${stage.id}'),
                    style: ZyraText.heading(size: 28),
                  ),
                  const SizedBox(height: 13),
                  Text(stage.summary, style: ZyraText.body(size: 14)),
                  const SizedBox(height: 32),
                  _DetailRow(label: 'YOU’LL ADD', body: stage.includes),
                  _DetailRow(label: 'WHO SEES IT', body: stage.visibility),
                  _DetailRow(
                    label: 'WHEN DONE',
                    body: stage.outcome,
                    bodyKey: const ValueKey('onboarding_stage_outcome'),
                  ),
                  const Spacer(),
                  _JourneyContinueButton(
                    key: const ValueKey('onboarding_stage_continue'),
                    label: stage.buttonLabel,
                    onTap: onContinue,
                  ),
                  if (onScrollUp != null) ...[
                    const SizedBox(height: 13),
                    const _PageDots(current: 1),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String body;
  final Key? bodyKey;

  const _DetailRow({required this.label, required this.body, this.bodyKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12, width: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: ZyraText.chapterLabel(color: ZyraColors.unlockText),
            ),
          ),
          Expanded(
            child: Text(
              body,
              key: bodyKey,
              style: ZyraText.subtext(size: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollUpCue extends StatelessWidget {
  final VoidCallback onTap;

  const _ScrollUpCue({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Welcome above',
      child: InkWell(
        key: const ValueKey('onboarding_stage_scroll_up'),
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white70,
                size: 20,
              ),
              Text(
                'Welcome above',
                style: ZyraText.subtext(size: 10, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyContinueButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _JourneyContinueButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 51,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ZyraColors.frostFill,
          border: Border.all(color: ZyraColors.glassBorder, width: 0.7),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: ZyraText.button(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 9),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int current;

  const _PageDots({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < 2; index++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: current == index ? 14 : 5,
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: current == index ? ZyraColors.unlockDot : Colors.white24,
            ),
          ),
          if (index == 0) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
