// Shared scaffold for every onboarding question screen — wires together
// the gradient background, top bar, scrollable content, privacy
// indicator, and FAB per Onboarding Rules & UX §SCREEN ANATOMY.
// No back button on question screens — back navigation is swipe-right,
// which PageView provides natively.

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'onboarding_top_bar.dart';
import 'privacy_indicator.dart';

class OnboardingScaffold extends StatelessWidget {
  final ZyraBackgroundVariant background;
  final String chapterName;
  final double chapterProgress;
  final bool chapterComplete;
  final String question;
  final String? subtext;
  final Widget content;
  final PrivacyLevel? privacy;
  final String? privacyOverrideText;
  final bool fabActive;
  final VoidCallback? onContinue;
  final bool devPreview;
  final VoidCallback? onDevSkip;
  final String devSkipLabel;

  /// Fix (2026-07-18): Onboarding Rules & UX §SCREEN ANATOMY specifies
  /// "No back button — users navigate back by swiping right (iOS
  /// standard gesture)." Every question screen in this app renders
  /// through this shared scaffold using a manual step index rather than
  /// a PageView, so that swipe gesture was never actually implemented —
  /// there was no way to correct an earlier answer across all ~200
  /// onboarding questions. This wires the swipe the spec always called
  /// for, without adding a visible back button (which the spec
  /// explicitly rules out).
  final VoidCallback? onSwipeBack;

  const OnboardingScaffold({
    super.key,
    required this.background,
    required this.chapterName,
    required this.chapterProgress,
    required this.question,
    required this.content,
    required this.fabActive,
    required this.onContinue,
    this.chapterComplete = false,
    this.subtext,
    this.privacy,
    this.privacyOverrideText,
    this.onSwipeBack,
    this.devPreview = false,
    this.onDevSkip,
    this.devSkipLabel = 'Skip question',
  });

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ZyraColors.luxuryDarkPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Need help?', style: ZyraText.heading(size: 16)),
              const SizedBox(height: 14),
              _HelpRow(
                'Why do we ask for your ${question.toLowerCase()}?',
                strong: true,
              ),
              const Divider(color: Colors.white12, height: 24),
              const _HelpRow('Help Centre'),
              const _HelpRow('Report a technical issue'),
              const _HelpRow('Report a billing issue'),
              const _HelpRow('Suggest an idea'),
              const _HelpRow('Contact Support'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: onSwipeBack == null
            ? null
            : (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity > 250) onSwipeBack!(); // rightward swipe
              },
        child: Container(
          decoration: BoxDecoration(
            gradient: ZyraColors.backgroundFor(background),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  OnboardingTopBar(
                    chapterName: chapterName,
                    chapterProgress: chapterProgress,
                    chapterComplete: chapterComplete,
                    onHelpTap: () => _showHelpSheet(context),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 90),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (onSwipeBack != null) ...[
                            Align(
                              alignment: Alignment.center,
                              child: _OnboardingBackCue(
                                onPressed: onSwipeBack!,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (!kReleaseMode &&
                              devPreview &&
                              onDevSkip != null) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: _DevSkipButton(
                                label: devSkipLabel,
                                onPressed: onDevSkip!,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Text(question, style: ZyraText.heading()),
                          if (subtext != null) ...[
                            const SizedBox(height: 8),
                            Text(subtext!, style: ZyraText.subtext()),
                          ],
                          const SizedBox(height: 28),
                          content,
                          if (privacy != null)
                            PrivacyIndicator(
                              level: privacy!,
                              overrideText: privacyOverrideText,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: MediaQuery.paddingOf(context).bottom + 14,
                child: _OnboardingContinueCue(
                  active: fabActive,
                  onPressed: onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevSkipButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _DevSkipButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label, developer only',
      child: TextButton.icon(
        key: const ValueKey('onboarding_dev_skip'),
        onPressed: onPressed,
        icon: const Icon(
          Icons.skip_next_rounded,
          size: 17,
          color: ZyraColors.unlockText,
        ),
        label: Text(
          '$label · DEV',
          style: ZyraText.subtext(size: 11.5, color: ZyraColors.unlockText),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          side: BorderSide(color: ZyraColors.unlockDot.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _OnboardingBackCue extends StatelessWidget {
  final VoidCallback onPressed;

  const _OnboardingBackCue({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Previous page',
      child: InkWell(
        key: const ValueKey('onboarding_back'),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white70,
                size: 21,
              ),
              Text(
                'Previous page',
                style: ZyraText.subtext(size: 9.5, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingContinueCue extends StatelessWidget {
  final bool active;
  final VoidCallback? onPressed;

  const _OnboardingContinueCue({required this.active, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = active ? ZyraColors.unlockText : Colors.white24;
    return Semantics(
      button: true,
      enabled: active,
      label: 'Continue',
      child: InkWell(
        key: const ValueKey('onboarding_continue'),
        onTap: active ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 25),
              const SizedBox(height: 3),
              Text(
                'Continue',
                style: ZyraText.subtext(size: 11.5, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final String text;
  final bool strong;
  const _HelpRow(this.text, {this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: strong
                  ? ZyraText.body(size: 14)
                  : ZyraText.subtext(size: 13),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
        ],
      ),
    );
  }
}
