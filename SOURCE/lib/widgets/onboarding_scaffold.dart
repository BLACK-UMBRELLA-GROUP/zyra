// Shared scaffold for every onboarding question screen — wires together
// the gradient background, top bar, scrollable content, privacy
// indicator, and FAB per Onboarding Rules & UX §SCREEN ANATOMY.
// No back button on question screens — back navigation is swipe-right,
// which PageView provides natively.

import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'fab_continue_button.dart';
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
  });

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1220),
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
              _HelpRow('Why do we ask for your ${question.toLowerCase()}?', strong: true),
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
        decoration: BoxDecoration(gradient: ZyraColors.backgroundFor(background)),
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
                        Text(question, style: ZyraText.heading()),
                        if (subtext != null) ...[
                          const SizedBox(height: 8),
                          Text(subtext!, style: ZyraText.subtext()),
                        ],
                        const SizedBox(height: 28),
                        content,
                        if (privacy != null)
                          PrivacyIndicator(level: privacy!, overrideText: privacyOverrideText),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            FabContinueButton(active: fabActive, onPressed: onContinue),
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
              style: strong ? ZyraText.body(size: 14) : ZyraText.subtext(size: 13),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
        ],
      ),
    );
  }
}

