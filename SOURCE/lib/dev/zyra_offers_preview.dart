import 'package:flutter/material.dart';

import '../data/zyra_membership_catalog.dart';
import '../models/zyra_offers_preview.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_confirm_sheet.dart';
import '../widgets/zyra_developer_title.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';

class ZyraPauseBeforeDeleteCard extends StatelessWidget {
  const ZyraPauseBeforeDeleteCard({super.key, required this.onPause});

  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: ZyraColors.journeyGold.withValues(alpha: .09),
      border: Border.all(color: ZyraColors.journeyGold.withValues(alpha: .38)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.pause_circle_outline,
            size: 23,
            color: ZyraColors.goldText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need a break instead?',
                  style: ZyraText.heading(size: 17),
                ),
                const SizedBox(height: 5),
                _copy(
                  'Pause My Profile hides you and keeps everything as it is. Come back whenever you’re ready.',
                  12.5,
                ),
                const SizedBox(height: 7),
                _copy(
                  'If you delete and come back later, you start again: a new identity check, and the ${ZyraMembershipCatalog.pounds(ZyraMembershipCatalog.basicJoiningPence)} joining fee if you choose Seeker Basic.',
                  12.5,
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  key: const ValueKey('offer_pause_before_delete'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 39),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    side: const BorderSide(color: ZyraColors.journeyGold),
                    foregroundColor: ZyraColors.goldTextStrong,
                  ),
                  onPressed: ZyraTapFeedback.onTap(context, onPause),
                  child: const Text('Pause my profile'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class ZyraRetentionPreviewSheet extends StatelessWidget {
  const ZyraRetentionPreviewSheet({
    super.key,
    required this.offer,
    required this.onStay,
    required this.onContinue,
  });

  final ZyraRetentionOfferPreview offer;
  final VoidCallback onStay, onContinue;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ZyraIvorySheet.decoration,
    child: ZyraIvorySheet(
      surfaceKey: const ValueKey('retention_offer_sheet'),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 19),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 21),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ZyraIvorySheetHandle(),
              const _GiftSymbol(size: 55),
              const SizedBox(height: 13),
              Text(
                offer.title,
                textAlign: TextAlign.center,
                style: ZyraText.heading(size: 21),
              ),
              const SizedBox(height: 6),
              Center(
                child: SizedBox(
                  width: 300,
                  child: _copy(
                    '${offer.amountLine} ${offer.afterLine}',
                    13.5,
                    center: true,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: SizedBox(
                  width: 300,
                  child: _copy(
                    'A thank-you for being with us. Offered ${offer.timing}. Charged to your Apple ID; cancel any time in App Store.',
                    12,
                    center: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _GoldAction(label: offer.stayLabel, onPressed: onStay),
              const SizedBox(height: 8),
              ZyraFloatingSurface(
                radius: 999,
                child: OutlinedButton(
                  key: const ValueKey('retention_offer_continue'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    backgroundColor: ZyraColors.cardSurface,
                    foregroundColor: ZyraColors.secondaryText,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: ZyraTapFeedback.onTap(context, onContinue),
                  child: const Text('Continue to cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ZyraEidGiftPreviewPage extends StatelessWidget {
  const ZyraEidGiftPreviewPage({
    super.key,
    required this.firstName,
    required this.gift,
    required this.onThanks,
  });

  final String firstName;
  final ZyraEidGiftPreview gift;
  final VoidCallback onThanks;

  @override
  Widget build(BuildContext context) => _OfferPage(
    title: 'Eid Mubarak',
    center: true,
    footer: _GoldAction(label: 'Thank you', onPressed: onThanks),
    children: [
      const _GiftSymbol(size: 84),
      const SizedBox(height: 18),
      Text(
        'Eid Mubarak, $firstName',
        textAlign: TextAlign.center,
        style: ZyraText.heading(size: 27),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: _copy(
          'Thank you for being part of ZYRA. May Allah accept from you and your family.',
          14,
          center: true,
        ),
      ),
      const SizedBox(height: 22),
      _OfferCard(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Text(
                'YOUR EID GIFT',
                style: ZyraText.chapterLabel(color: ZyraColors.goldTextStrong),
              ),
              const SizedBox(height: 8),
              Text(
                gift.title,
                textAlign: TextAlign.center,
                style: ZyraText.heading(size: 21),
              ),
              const SizedBox(height: 8),
              _copy(gift.detail, 13.5, center: true),
            ],
          ),
        ),
      ),
    ],
  );
}

class ZyraRamadanDrawPreviewPage extends StatefulWidget {
  const ZyraRamadanDrawPreviewPage({
    super.key,
    required this.entered,
    required this.onEnter,
  });

  final bool entered;
  final VoidCallback onEnter;

  @override
  State<ZyraRamadanDrawPreviewPage> createState() =>
      _ZyraRamadanDrawPreviewPageState();
}

class _ZyraRamadanDrawPreviewPageState
    extends State<ZyraRamadanDrawPreviewPage> {
  bool _rulesOpen = false;

  @override
  void didUpdateWidget(covariant ZyraRamadanDrawPreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entered && !oldWidget.entered) _rulesOpen = false;
  }

  @override
  Widget build(BuildContext context) => _OfferPage(
    title: 'Ramadan gift draw',
    footer: widget.entered
        ? Container(
            key: const ValueKey('preview_draw_entered'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: ZyraColors.positiveGreen.withValues(alpha: .09),
              border: Border.all(
                color: ZyraColors.positiveGreen.withValues(alpha: .35),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: ZyraColors.greenText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You’re in. We’ll tell you on Eid al-Fitr if you’ve won. Ramadan Mubarak.',
                    style: ZyraText.body(
                      size: 13.5,
                      color: ZyraColors.espresso,
                    ),
                  ),
                ),
              ],
            ),
          )
        : _GoldAction(label: 'Enter the draw', onPressed: widget.onEnter),
    children: [
      const SizedBox(height: 12),
      const _GiftSymbol(size: 76),
      const SizedBox(height: 14),
      Text(
        'Ramadan Mubarak',
        textAlign: TextAlign.center,
        style: ZyraText.heading(size: 26),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: _copy(
          'Enter once for a chance to win 6 months of ZYRA One. Free to enter — no payment and nothing to buy.',
          14,
          center: true,
        ),
      ),
      const SizedBox(height: 30),
      Text(
        'HOW IT WORKS',
        style: ZyraText.chapterLabel(color: ZyraColors.secondaryText),
      ),
      const SizedBox(height: 10),
      _OfferCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 4),
          child: Column(
            children: [
              _drawStep(
                Icons.touch_app_outlined,
                'Tap Enter once',
                'One entry per person. Any member can enter.',
              ),
              const Divider(height: 1, color: ZyraColors.divider),
              _drawStep(
                Icons.event_outlined,
                'Winners chosen after Ramadan',
                'At random, and told in the app on Eid al-Fitr.',
              ),
              const Divider(height: 1, color: ZyraColors.divider),
              _drawStep(
                Icons.verified_user_outlined,
                'Win 6 months of ZYRA One',
                'Seeker One or Guardian One. It doesn’t renew by itself.',
              ),
            ],
          ),
        ),
      ),
      TextButton(
        key: const ValueKey('preview_draw_rules'),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        onPressed: ZyraTapFeedback.onTap(
          context,
          () => setState(() => _rulesOpen = !_rulesOpen),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('Official rules', style: ZyraText.body(size: 15)),
            ),
            _copy(_rulesOpen ? 'Hide' : 'Read', 13),
          ],
        ),
      ),
      if (_rulesOpen)
        _copy(
          'ZYRA (Black Umbrella Group) runs this draw. Free to enter, one entry per person, open to members aged 18 and over. Winners are chosen at random after Ramadan and must have a verified ZYRA account to claim. The prize is 6 months of Seeker One or Guardian One, with no renewal charge. Apple is not a sponsor of this draw and is not involved in it in any way.',
          13.5,
        ),
    ],
  );

  Widget _drawStep(IconData icon, String title, String detail) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ZyraColors.goldText, size: 19),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ZyraText.body(size: 15)),
              const SizedBox(height: 3),
              _copy(detail, 13),
            ],
          ),
        ),
      ],
    ),
  );
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 20,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: ZyraColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    ),
  );
}

class _OfferPage extends StatelessWidget {
  const _OfferPage({
    required this.title,
    required this.children,
    required this.footer,
    this.center = false,
  });

  final String title;
  final List<Widget> children;
  final Widget footer;
  final bool center;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(1, 16, 1, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ZyraDeveloperTitle(child: Text(title, style: ZyraText.pageTitle())),
            const SizedBox(height: 15),
            Expanded(
              child: LayoutBuilder(
                builder: (context, space) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (space.maxHeight - 16).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: Align(
                      alignment: center
                          ? const Alignment(0, .16)
                          : Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            footer,
          ],
        ),
      ),
    ),
  );
}

class _GoldAction extends StatelessWidget {
  const _GoldAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(999)),
      boxShadow: ZyraFloatingSurface.goldShadows,
    ),
    child: FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        backgroundColor: ZyraColors.goldTextFill,
        foregroundColor: ZyraColors.espresso,
        shape: const StadiumBorder(side: BorderSide.none),
        textStyle: ZyraText.body(size: 15),
      ),
      onPressed: ZyraTapFeedback.onTap(context, onPressed),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}

class _GiftSymbol extends StatelessWidget {
  const _GiftSymbol({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ZyraColors.journeyGold.withValues(alpha: .12),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.redeem, size: size * .45, color: ZyraColors.goldText),
    ),
  );
}

Widget _copy(String text, double size, {bool center = false}) => Text(
  text,
  textAlign: center ? TextAlign.center : TextAlign.start,
  style: ZyraText.body(size: size, color: ZyraColors.secondaryText),
);
