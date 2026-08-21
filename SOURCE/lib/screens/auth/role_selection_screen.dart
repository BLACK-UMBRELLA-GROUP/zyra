// First-use path selection.
//
// Founder direction, 2026-08-19: this is no longer framed as choosing a
// permanent account type. It asks which ZYRA experience the person needs
// first. One trusted identity may later carry both Seeker and Guardian
// contexts without another sign-in; the server activation for that second
// context remains behind the Founder's explicit migration gate.

import 'package:flutter/material.dart';
import '../../services/zyra_auth.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../onboarding/onboarding_flow.dart';
import '../onboarding/account_path_overview_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).vertical -
                    52,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('ZYRA', style: ZyraText.wordmark(size: 20)),
                      const Spacer(),
                      Text(
                        'ACCOUNT SETUP · 1 OF 2',
                        style: ZyraText.chapterLabel(color: Colors.white38),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: const LinearProgressIndicator(
                      value: 0.5,
                      minHeight: 1.5,
                      backgroundColor: ZyraColors.progressTrack,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ZyraColors.progressFill,
                      ),
                    ),
                  ),
                  const SizedBox(height: 62),
                  Text(
                    'CHOOSE WHERE TO BEGIN',
                    style: ZyraText.chapterLabel(color: Colors.white54),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'How will you use ZYRA first?',
                    style: ZyraText.heading(size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Start with the experience you need today. You can add '
                    'the other later without creating another login.',
                    style: ZyraText.subtext(size: 13.5),
                  ),
                  const SizedBox(height: 30),
                  _RoleCard(
                    icon: Icons.favorite_border,
                    title: 'Seek marriage',
                    description:
                        'Build my profile and begin my own marriage journey.',
                    onTap: () => _proceedAsSeeker(context),
                  ),
                  const SizedBox(height: 14),
                  _RoleCard(
                    icon: Icons.shield_outlined,
                    title: 'Support as Guardian',
                    description:
                        'Guide someone I care for through their journey.',
                    onTap: () => _proceedAsWali(context),
                  ),
                  const SizedBox(height: 26),
                  Center(
                    child: Text(
                      'One identity · one secure sign-in · two experiences',
                      textAlign: TextAlign.center,
                      style: ZyraText.subtext(
                        size: 10.5,
                        color: Colors.white38,
                      ),
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

  void _proceedAsSeeker(BuildContext context) {
    final firstName = ZyraAuth.onboardingFirstName;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OnboardingFlow(welcomeName: firstName)),
    );
  }

  void _proceedAsWali(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const GuardianOnboardingOverviewScreen(),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ZyraColors.iconButtonBg,
        border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ZyraColors.unlockDot.withValues(alpha: 0.08),
                    border: Border.all(
                      color: ZyraColors.unlockDot.withValues(alpha: 0.65),
                    ),
                  ),
                  child: Icon(icon, size: 20, color: ZyraColors.unlockText),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ZyraText.body(size: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(description, style: ZyraText.subtext(size: 11.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
