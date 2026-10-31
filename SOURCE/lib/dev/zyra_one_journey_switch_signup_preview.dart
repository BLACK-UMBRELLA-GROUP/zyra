import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_account_switch_sheet.dart';

/// A disposable missing-context example, not account creation or onboarding.
///
/// [guardian] describes the current profile. The parent owns all guarded
/// navigation; this view cannot change a role, identity, plan or member record.
class ZyraSwitchSignupPreview extends StatelessWidget {
  const ZyraSwitchSignupPreview({
    super.key,
    required this.guardian,
    required this.setupOverview,
    required this.currentMembership,
    required this.onStartSetup,
    required this.onReturnToProfile,
  });

  final bool guardian;
  final bool setupOverview;
  final String currentMembership;
  final VoidCallback onStartSetup;
  final VoidCallback onReturnToProfile;

  String get _current => guardian ? 'Guardian' : 'Seeker';
  String get _target => guardian ? 'Seeker' : 'Guardian';
  IconData get _targetIcon =>
      guardian ? Icons.person_outline : Icons.shield_outlined;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ZyraShadowScrollView(
      key: ValueKey(
        setupOverview ? 'concept_switch_setup' : 'concept_switch_signup',
      ),
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              setupOverview ? 'Set up your $_target profile' : 'Switch Account',
              style: ZyraText.pageTitle(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            setupOverview
                ? 'A separate profile, with the same login. Here is what comes next.'
                : 'Your $_current profile is ready. Add a $_target profile without another email or signing out.',
            style: ZyraText.subtext(size: 14).copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          if (setupOverview)
            _setupSteps()
          else ...[
            _currentProfile(),
            const SizedBox(height: 14),
            _missingProfile(),
          ],
          const SizedBox(height: 24),
          _sharedLogin(),
          const SizedBox(height: 20),
          Text(
            'Setup preview · no profile is created.',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 11.5),
          ),
          const SizedBox(height: 16),
          _action(
            id: 'concept_switch_return_profile',
            label: 'Back to Profile',
            onPressed: onReturnToProfile,
          ),
        ],
      ),
    ),
  );

  Widget _currentProfile() => _card(
    id: 'concept_switch_current',
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _icon(guardian ? Icons.shield_outlined : Icons.person_outline),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_current profile', style: ZyraText.heading(size: 19)),
              const SizedBox(height: 5),
              Text(currentMembership, style: ZyraText.subtext(size: 13)),
              const SizedBox(height: 12),
              Text(
                'CURRENT',
                style: ZyraText.chapterLabel(color: ZyraColors.goldText),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _missingProfile() => _card(
    id: 'concept_switch_missing',
    emphasized: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _icon(_targetIcon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_target profile', style: ZyraText.heading(size: 20)),
                  const SizedBox(height: 5),
                  Text(
                    'Not set up yet',
                    style: ZyraText.subtext(
                      size: 13,
                      color: ZyraColors.goldText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          guardian
              ? 'Create your own Seeker profile when you are ready to begin your marriage journey.'
              : 'Create your Guardian profile before you can support someone in their Journey.',
          style: ZyraText.subtext(size: 13).copyWith(height: 1.5),
        ),
        const SizedBox(height: 20),
        _action(
          id: 'concept_switch_start_setup',
          label: 'Set up $_target profile',
          onPressed: onStartSetup,
          emphasized: true,
        ),
      ],
    ),
  );

  Widget _setupSteps() {
    final steps = guardian
        ? const [
            (
              'Your profile and photos',
              'Add the details and photos you want other Seekers to see.',
            ),
            (
              'Your values and compatibility',
              'Complete your own preferences and compatibility answers.',
            ),
            (
              'Your Seeker membership',
              'Choose membership for this profile. Nothing is purchased automatically.',
            ),
            (
              'Review before going live',
              'Your Seeker profile is not published just by opening setup.',
            ),
          ]
        : const [
            (
              'Your Guardian details',
              'Confirm your details and your relationship to the person you support.',
            ),
            (
              'Add one photo',
              'Add the single profile photo required for Guardian setup.',
            ),
            (
              'Your Guardian membership',
              'Choose membership for this profile. Nothing is purchased automatically.',
            ),
            (
              'Your responsibilities',
              'Review your role and how to link with the person you support.',
            ),
          ];
    return _card(
      id: 'concept_switch_setup_steps',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Divider(height: 1, color: ZyraColors.surfaceBorder),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.circle_outlined,
                      size: 18,
                      color: ZyraColors.unlockText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[index].$1, style: ZyraText.body(size: 14)),
                      const SizedBox(height: 6),
                      Text(
                        steps[index].$2,
                        style: ZyraText.subtext(size: 12).copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sharedLogin() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ONE LOGIN',
          style: ZyraText.chapterLabel(color: ZyraColors.goldText),
        ),
        const SizedBox(height: 10),
        Text(
          'Your existing identity check stays with your login.',
          style: ZyraText.subtext(size: 12.5).copyWith(height: 1.5),
        ),
        const SizedBox(height: 8),
        Text(
          ZyraAccountContextPolicy.separateSummary,
          style: ZyraText.subtext(size: 12.5).copyWith(height: 1.5),
        ),
      ],
    ),
  );

  Widget _icon(IconData icon) => ExcludeSemantics(
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ZyraColors.iconButtonBg,
      ),
      child: Icon(icon, size: 22, color: ZyraColors.unlockText),
    ),
  );

  Widget _card({String? id, bool emphasized = false, required Widget child}) =>
      ZyraFloatingSurface(
        radius: 20,
        circle: false,
        gold: false,
        child: Container(
          key: id == null ? null : ValueKey(id),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: emphasized
                ? ZyraColors.surfaceEmphasisFill
                : ZyraColors.surfaceFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: emphasized
                  ? ZyraColors.surfaceEmphasisBorder
                  : ZyraColors.surfaceBorder,
            ),
          ),
          child: child,
        ),
      );

  Widget _action({
    required String id,
    required String label,
    required VoidCallback onPressed,
    bool emphasized = false,
  }) => Builder(
    builder: (context) => ZyraFloatingSurface(
      radius: 999,
      circle: false,
      gold: false,
      child: OutlinedButton(
        key: ValueKey(id),
        onPressed: ZyraTapFeedback.onTap(context, onPressed),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          foregroundColor: ZyraColors.foreground,
          backgroundColor: emphasized ? ZyraColors.surfaceEmphasisFill : null,
          side: BorderSide(
            color: emphasized
                ? ZyraColors.surfaceEmphasisBorder
                : ZyraColors.surfaceBorder,
          ),
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: ZyraText.button(size: 14),
        ),
      ),
    ),
  );
}
