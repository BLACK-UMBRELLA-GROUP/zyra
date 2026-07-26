// Role Selection — Script_V1.md: "Role Selection → Onboarding → Home."
// Core roles per ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.md: Seeker, Wali
// (Connector role retired, DR-077). Admin is never self-selected here —
// assigned manually per the Database Schema doc.

import 'package:flutter/material.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../onboarding/onboarding_flow.dart';
import '../wali/wali_onboarding_flow.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text('Who are you joining as?', style: ZyraText.heading(size: 24)),
                const SizedBox(height: 8),
                Text('This determines how ZYRA guides your journey.', style: ZyraText.subtext()),
                const SizedBox(height: 32),
                _RoleCard(
                  title: 'Seeker',
                  description: 'Looking for your own marriage journey, with your Wali involved at the right moments.',
                  onTap: () => _proceedAsSeeker(context),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  title: 'Wali (Guardian)',
                  description: 'Supporting and overseeing a Seeker\'s journey as their Islamic guardian.',
                  onTap: () => _proceedAsWali(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _proceedAsSeeker(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingFlow()),
    );
  }

  // Fix (2026-07-18): this used to call _proceed(context) same as
  // Seeker, sending Walis through the Seeker's name/gender/DOB + photos
  // onboarding — completely wrong persona. See wali_onboarding_flow.dart.
  void _proceedAsWali(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WaliOnboardingFlow()),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({required this.title, required this.description, required this.onTap});

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
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ZyraText.body(size: 16, color: Colors.white)),
                const SizedBox(height: 6),
                Text(description, style: ZyraText.subtext()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
