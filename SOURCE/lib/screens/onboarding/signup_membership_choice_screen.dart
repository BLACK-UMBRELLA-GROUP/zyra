import 'package:flutter/material.dart';

import '../../data/zyra_membership_catalog.dart';
import '../../models/zyra_signup_membership_choice.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/onboarding_scaffold.dart';

/// The account flow owns saving and navigation. Choosing a card never grants
/// membership, begins a trial, charges a fee or marks identity as verified.
class SignupMembershipChoiceScreen extends StatelessWidget {
  const SignupMembershipChoiceScreen({
    super.key,
    required this.role,
    required this.choice,
    required this.onChanged,
    required this.onContinue,
    required this.onBack,
    this.background = ZyraBackgroundVariant.neutral,
    this.saving = false,
    this.error,
    this.devPreview = false,
    this.onDevSkip,
    this.expectedUserId,
  });

  final ZyraSignupRole role;
  final ZyraSignupMembershipChoice? choice;
  final ValueChanged<ZyraSignupMembershipChoice> onChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final ZyraBackgroundVariant background;
  final bool saving;
  final String? error;
  final bool devPreview;
  final VoidCallback? onDevSkip;
  final String? expectedUserId;

  bool get _guardian => role == ZyraSignupRole.guardian;

  // Founder-requested offer comparison, not an active StoreKit product. Keep
  // ordinary pricing/trial copy intact until the trial/eligibility decision and
  // exact commerce activation are approved. The flow supplies protected preview.
  bool get _introOfferPreview => devPreview && !_guardian;
  // Family's requested comparison applies to both signup roles. Ordinary
  // commerce stays unchanged, just as for the protected Seeker One offer.
  bool get _familyIntroOfferPreview => devPreview;
  static const _previewIntroMonthPence = 499;

  void _select(ZyraSignupMembershipKind kind) {
    if (saving || choice?.kind == kind) return;
    onChanged(
      ZyraSignupMembershipChoice(
        kind: kind,
        seekers: kind == ZyraSignupMembershipKind.family && !_guardian ? 1 : 0,
        guardians: kind == ZyraSignupMembershipKind.family && _guardian ? 1 : 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final one = _guardian
        ? ZyraMembershipProduct.guardianOne
        : ZyraMembershipProduct.seekerOne;
    final basic = _guardian
        ? ZyraMembershipProduct.guardianBasic
        : ZyraMembershipProduct.seekerBasic;
    return OnboardingScaffold(
      key: const ValueKey('signup_membership_choice'),
      background: background,
      chapterName: 'Membership',
      chapterProgress: choice == null ? 0 : 1,
      progressLabel: 'YOUR MEMBERSHIP CHOICE',
      question: 'Choose how to join',
      subtext:
          error ??
          (_introOfferPreview
              ? 'Basic or your first month of One — both start at £4.99.'
              : 'Choose the membership that suits your journey.'),
      frameContent: false,
      fabActive: !saving && choice?.isValidFor(role) == true,
      onContinue: onContinue,
      onSwipeBack: saving ? null : onBack,
      devPreview: devPreview,
      onDevSkip: saving ? null : onDevSkip,
      devSkipLabel: 'Skip',
      showAccountExit: true,
      accountExitExpectedUserId: expectedUserId,
      continueActionKey: const ValueKey('signup_membership_continue'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChoiceCard(
            key: const ValueKey('signup_membership_basic'),
            icon: Icons.person_outline_rounded,
            title: ZyraMembershipCatalog.title(basic),
            price:
                '${ZyraMembershipCatalog.pounds(ZyraMembershipCatalog.basicJoiningPence)} once',
            detail: 'Joining and verification. No monthly subscription.',
            selected: choice?.kind == ZyraSignupMembershipKind.basic,
            onTap: saving
                ? null
                : () => _select(ZyraSignupMembershipKind.basic),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            key: const ValueKey('signup_membership_one'),
            icon: Icons.workspace_premium_outlined,
            title: ZyraMembershipCatalog.title(one),
            price: _introOfferPreview
                ? '${ZyraMembershipCatalog.pounds(_previewIntroMonthPence)} first month'
                : ZyraMembershipCatalog.price(one),
            badge: _introOfferPreview
                ? (choice?.kind == ZyraSignupMembershipKind.basic
                      ? 'Same starting price as Basic'
                      : 'First month offer')
                : null,
            renewal: _introOfferPreview
                ? 'Then ${ZyraMembershipCatalog.pounds(ZyraMembershipCatalog.seekerOneMonthlyPence)}/month. Cancel renewal anytime.'
                : null,
            detail: _introOfferPreview
                ? '3 Active Journeys. Joining and verification included.'
                : _guardian
                ? 'Monthly access to Guardian One features.'
                : 'Monthly access to Seeker One features. A 14-day trial when eligible.',
            action:
                _introOfferPreview &&
                    choice?.kind == ZyraSignupMembershipKind.basic
                ? FilledButton(
                    key: const ValueKey('signup_membership_try_one'),
                    onPressed: saving
                        ? null
                        : () => _select(ZyraSignupMembershipKind.one),
                    style: FilledButton.styleFrom(
                      foregroundColor: ZyraColors.luxuryDarkPurple,
                      backgroundColor: ZyraColors.journeyGold,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      textStyle: ZyraText.body(size: 13),
                    ),
                    child: const Text(
                      'Try Seeker One for £4.99',
                      textAlign: TextAlign.center,
                    ),
                  )
                : null,
            selected: choice?.kind == ZyraSignupMembershipKind.one,
            onTap: saving ? null : () => _select(ZyraSignupMembershipKind.one),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            key: const ValueKey('signup_membership_family'),
            icon: Icons.groups_outlined,
            title: 'ZYRA Family',
            price: _familyIntroOfferPreview
                ? '${ZyraMembershipCatalog.pounds(ZyraMembershipCatalog.familyIntroMonthPerPlacePence)} per person for the first month'
                : 'Monthly places for Seekers and Guardians',
            emphasizePrice: _familyIntroOfferPreview,
            renewal: _familyIntroOfferPreview
                ? 'Then your chosen Family plan renews monthly. Cancel renewal anytime.'
                : null,
            renewalKey: const ValueKey('signup_membership_family_renewal'),
            detail: 'Choose the One places you need, including your own role.',
            selected: choice?.kind == ZyraSignupMembershipKind.family,
            onTap: saving
                ? null
                : () => _select(ZyraSignupMembershipKind.family),
          ),
          if (choice?.kind == ZyraSignupMembershipKind.family) ...[
            const SizedBox(height: 16),
            _familyEstimate(),
          ],
          const SizedBox(height: 18),
          Text(
            _introOfferPreview || _familyIntroOfferPreview
                ? 'Offer design preview only. No payment or subscription starts here.'
                : 'This saves your choice only. Checkout is not available in this build; no payment will be taken and no trial or paid access starts here.',
            style: ZyraText.subtext(size: 12.5),
          ),
          if (choice?.kind == ZyraSignupMembershipKind.one &&
              !_guardian &&
              !_introOfferPreview) ...[
            const SizedBox(height: 12),
            Text(
              ZyraMembershipCatalog.trialTerms,
              style: ZyraText.subtext(size: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _familyEstimate() {
    final selected = choice!;
    final quote = ZyraMembershipCatalog.familyQuote(
      selected.seekers,
      selected.guardians,
    );
    void change(bool seeker, int delta) {
      if (saving) return;
      onChanged(
        ZyraSignupMembershipChoice(
          kind: ZyraSignupMembershipKind.family,
          seekers: selected.seekers + (seeker ? delta : 0),
          guardians: selected.guardians + (seeker ? 0 : delta),
        ),
      );
    }

    return Container(
      key: const ValueKey('signup_membership_family_estimate'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZyraColors.surfaceEmphasisFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ZyraColors.journeyGold.withValues(alpha: .32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Include one ${_guardian ? 'Guardian' : 'Seeker'} place for you.',
            style: ZyraText.subtext(size: 12.5),
          ),
          const SizedBox(height: 10),
          for (final seeker in [true, false])
            Row(
              children: [
                Expanded(
                  child: Text(
                    seeker ? 'Seeker One' : 'Guardian One',
                    style: ZyraText.body(size: 14),
                  ),
                ),
                IconButton(
                  key: ValueKey(
                    'signup_family_${seeker ? 'seekers' : 'guardians'}_remove',
                  ),
                  tooltip: 'Remove ${seeker ? 'Seeker' : 'Guardian'} place',
                  onPressed:
                      saving ||
                          (seeker ? selected.seekers : selected.guardians) <=
                              (seeker == !_guardian ? 1 : 0)
                      ? null
                      : () => change(seeker, -1),
                  icon: const Icon(Icons.remove_rounded),
                ),
                Text(
                  '${seeker ? selected.seekers : selected.guardians}',
                  key: ValueKey(
                    'signup_family_${seeker ? 'seekers' : 'guardians'}_count',
                  ),
                  style: ZyraText.body(size: 16),
                ),
                IconButton(
                  key: ValueKey(
                    'signup_family_${seeker ? 'seekers' : 'guardians'}_add',
                  ),
                  tooltip: 'Add ${seeker ? 'Seeker' : 'Guardian'} place',
                  onPressed:
                      saving ||
                          (seeker ? selected.seekers : selected.guardians) >= 10
                      ? null
                      : () => change(seeker, 1),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          const SizedBox(height: 10),
          if (_familyIntroOfferPreview) ...[
            Text(
              '${ZyraMembershipCatalog.pounds(quote.introFirstMonthPence)} first month total',
              key: const ValueKey('signup_family_first_month_total'),
              style: ZyraText.body(size: 18, color: ZyraColors.journeyGold),
            ),
            Text(
              '${quote.members} ${quote.members == 1 ? 'person' : 'people'} × ${ZyraMembershipCatalog.pounds(ZyraMembershipCatalog.familyIntroMonthPerPlacePence)}',
              key: const ValueKey('signup_family_first_month_calculation'),
              style: ZyraText.subtext(size: 12.5),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            _familyIntroOfferPreview
                ? 'Then ${ZyraMembershipCatalog.pounds(quote.formulaMonthlyPence)} / month estimate'
                : '${ZyraMembershipCatalog.pounds(quote.formulaMonthlyPence)} / month estimate',
            key: const ValueKey('signup_family_monthly_estimate'),
            style: ZyraText.body(size: 16, color: ZyraColors.journeyGold),
          ),
          Text(
            _familyIntroOfferPreview
                ? '${quote.discountPercent}% saving on monthly renewals across ${quote.members} places.'
                : '${quote.discountPercent}% saving across ${quote.members} places.',
            style: ZyraText.subtext(size: 12.5),
          ),
          const SizedBox(height: 10),
          Text(
            'The App Store will show the exact local price before purchase. Family has no trial; selecting places does not invite or link anyone.',
            style: ZyraText.subtext(size: 12),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.price,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.badge,
    this.renewal,
    this.renewalKey = const ValueKey('signup_membership_renewal'),
    this.action,
    this.emphasizePrice = true,
  });

  final IconData icon;
  final String title;
  final String price;
  final String detail;
  final bool selected;
  final VoidCallback? onTap;
  final String? badge;
  final String? renewal;
  final Key renewalKey;
  final Widget? action;
  final bool emphasizePrice;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected
          ? ZyraColors.surfaceEmphasisFill
          : ZyraColors.iconButtonBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? ZyraColors.journeyGold.withValues(alpha: .7)
              : ZyraColors.iconButtonBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: ZyraColors.journeyGold, size: 25),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: ZyraText.heading(size: 19)),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    selected
                        ? Icons.check_circle_outline_rounded
                        : Icons.circle_outlined,
                    color: selected
                        ? ZyraColors.journeyGold
                        : ZyraColors.foregroundMuted,
                    size: 20,
                  ),
                ],
              ),
              if (badge != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    key: const ValueKey('signup_membership_offer_badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ZyraColors.journeyGold.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: ZyraText.body(
                        size: 11,
                        color: ZyraColors.journeyGold,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                price,
                style: ZyraText.body(
                  size: emphasizePrice ? 18 : 14,
                  color: ZyraColors.journeyGold,
                ),
              ),
              if (renewal != null) ...[
                const SizedBox(height: 5),
                Text(
                  renewal!,
                  key: renewalKey,
                  style: ZyraText.body(size: 12.5),
                ),
              ],
              const SizedBox(height: 7),
              Text(detail, style: ZyraText.subtext(size: 13)),
              if (action != null) ...[const SizedBox(height: 12), action!],
            ],
          ),
        ),
      ),
    ),
  );
}
