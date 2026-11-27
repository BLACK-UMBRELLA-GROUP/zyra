import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_developer_title.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';

/// LOCK 44 presentation only. The owning shell supplies account-scoped sample
/// state and fresh action callbacks; this page has no member or server access.
class ZyraPausePrivatePreview extends StatelessWidget {
  const ZyraPausePrivatePreview({
    super.key,
    required this.privatePage,
    required this.paused,
    required this.privateMode,
    required this.seekerOne,
    required this.onPause,
    required this.onShowProfile,
    required this.onPrivateChanged,
    required this.onUpgrade,
  });

  final bool privatePage, paused, privateMode, seekerOne;
  final VoidCallback onPause;
  final VoidCallback onShowProfile, onUpgrade;
  final ValueChanged<bool> onPrivateChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
    child: Material(
      key: ValueKey(privatePage ? 'private_mode_page' : 'pause_profile_page'),
      color: Colors.transparent,
      child: DefaultTextStyle.merge(
        style: const TextStyle(letterSpacing: 0, height: 1.45),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) => ZyraShadowScrollView(
              key: const ValueKey('pause_private_scroll'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport.maxHeight - 16),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: ZyraDeveloperTitle(
                          child: Text(
                            privatePage ? 'Private mode' : 'Pause My Profile',
                            key: const ValueKey('pause_private_title'),
                            style: ZyraText.pageTitle(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (privatePage)
                        ..._privateContent(context)
                      else
                        ..._pauseContent(),
                      const SizedBox(height: 14),
                      const Spacer(),
                      if (!privatePage || !seekerOne)
                        _mainButton(
                          context,
                          privatePage
                              ? 'Private mode comes with Seeker One'
                              : paused
                              ? 'Show my profile again'
                              : 'Pause my profile',
                          privatePage
                              ? onUpgrade
                              : paused
                              ? onShowProfile
                              : onPause,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> _pauseContent() => [
    const SizedBox(height: 6),
    _status(),
    _section('WHILE PAUSED'),
    _explanations(const [
      (
        Icons.visibility_off_outlined,
        'You are hidden from Profiles',
        'No one new can find you or send you a request.',
      ),
      (
        Icons.pause_circle_outline,
        'No new requests either way',
        'You can’t send requests while paused. Requests waiting for you stay until you return.',
      ),
      (
        Icons.people_outline,
        'Your Journeys carry on',
        'Nothing changes for the people you are already in a Journey with.',
      ),
    ]),
    Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 0),
      child: Text(
        'Your profile, Guardians, membership and Journeys are kept. Your membership keeps running while paused.',
        style: ZyraText.subtext(size: 12.5).copyWith(height: 1.5),
      ),
    ),
  ];

  List<Widget> _privateContent(BuildContext context) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
      child: Text(
        'Browse quietly. You stay out of Profiles, but you can still find people and send Journey requests.',
        style: ZyraText.subtext(size: 14).copyWith(height: 1.5),
      ),
    ),
    _privateSwitch(context),
    _section('HOW IT WORKS'),
    _explanations(const [
      (
        Icons.visibility_off_outlined,
        'You don’t appear in Profiles',
        'No one finds you by browsing.',
      ),
      (
        Icons.search,
        'You can still browse and send requests',
        'The person you send a request to sees your full profile, as normal.',
      ),
      (
        Icons.people_outline,
        'Your Journeys carry on',
        'Nothing changes for the people you are already in a Journey with.',
      ),
    ]),
    Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
      child: Text(
        'Want a full break instead? Use Pause My Profile.',
        style: ZyraText.subtext(
          size: 12.5,
          color: ZyraColors.strongSecondaryText,
        ).copyWith(height: 1.5),
      ),
    ),
  ];

  Widget _card(Widget child, {EdgeInsets padding = EdgeInsets.zero}) =>
      ZyraFloatingSurface(
        radius: 16,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: ZyraColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ZyraColors.surfaceBorder),
          ),
          child: child,
        ),
      );

  Widget _section(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 30, 2, 10),
    child: Text(
      text,
      style: ZyraText.subtext(size: 10.5).copyWith(letterSpacing: 1),
    ),
  );

  Widget _status() {
    final color = paused ? ZyraColors.journeyGold : ZyraColors.greenText;
    final detail = paused
        ? 'Until you turn it off'
        : 'Families can find you in Profiles';
    return _card(
      Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: paused ? .65 : .5),
              ),
            ),
            child: Icon(
              paused ? Icons.pause_circle_outline : Icons.check,
              size: 22,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paused ? 'Your profile is paused' : 'Your profile is visible',
                  key: const ValueKey('pause_profile_status'),
                  style: ZyraText.body(size: 17),
                ),
                const SizedBox(height: 2),
                Text(detail, style: ZyraText.subtext(size: 12.5)),
              ],
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  Widget _explanations(List<(IconData, String, String)> rows) => _card(
    Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            Divider(height: 1, thickness: 1, color: ZyraColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(rows[i].$1, color: ZyraColors.journeyGold, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rows[i].$2, style: ZyraText.body(size: 14)),
                      const SizedBox(height: 3),
                      Text(
                        rows[i].$3,
                        style: ZyraText.subtext(
                          size: 12.5,
                        ).copyWith(height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );

  Widget _privateSwitch(BuildContext context) => _card(
    Semantics(
      label: 'Private mode',
      toggled: privateMode && seekerOne,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('private_mode_switch'),
          borderRadius: BorderRadius.circular(16),
          onTap: ZyraTapFeedback.onTap(
            context,
            () => onPrivateChanged(!privateMode),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Private mode',
                              style: ZyraText.body(size: 15),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: ZyraColors.journeyGold.withValues(
                                    alpha: .6,
                                  ),
                                ),
                              ),
                              child: Text(
                                'ONE',
                                style: ZyraText.body(
                                  size: 10.5,
                                  color: ZyraColors.goldText,
                                ).copyWith(letterSpacing: 1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          privateMode && seekerOne
                              ? 'On · only people you send a request to can see you'
                              : 'Off · families can find you in Profiles',
                          style: ZyraText.subtext(size: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ExcludeSemantics(
                    child: Container(
                      width: 46,
                      height: 28,
                      padding: const EdgeInsets.all(3),
                      alignment: privateMode && seekerOne
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: privateMode && seekerOne
                            ? ZyraColors.goldTextFill
                            : ZyraColors.warmOverlay.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: ZyraColors.ivoryTop,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
  );

  Widget _mainButton(BuildContext context, String label, VoidCallback onTap) =>
      ZyraFloatingSurface(
        gold: true,
        radius: 999,
        child: FilledButton(
          key: const ValueKey('pause_private_action'),
          onPressed: ZyraTapFeedback.onTap(context, onTap),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: ZyraColors.actionFill,
            foregroundColor: ZyraColors.onAction,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: const StadiumBorder(),
            side: BorderSide.none,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: ZyraText.button(size: 14, color: ZyraColors.onAction)
                .copyWith(
                  letterSpacing: 0,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
          ),
        ),
      );
}

/// LOCK 44 pp07: the Profiles tab retains its title and shared navigation.
class ZyraPausedProfilesCard extends StatelessWidget {
  const ZyraPausedProfilesCard({super.key, required this.onShowProfile});
  final VoidCallback onShowProfile;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, viewport) => ZyraShadowScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: viewport.maxHeight),
        child: ZyraFloatingSurface(
          child: Container(
            key: const ValueKey('paused_profiles_card'),
            constraints: BoxConstraints(minHeight: viewport.maxHeight),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ZyraColors.cardSurface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: ZyraColors.journeyGold.withValues(alpha: .3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ZyraColors.journeyGold.withValues(alpha: .5),
                      ),
                    ),
                    child: const Icon(
                      Icons.pause_circle_outline,
                      size: 28,
                      color: ZyraColors.journeyGold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your profile is paused',
                  textAlign: TextAlign.center,
                  style: ZyraText.body(
                    size: 22,
                  ).copyWith(fontWeight: FontWeight.w300, height: 1.45),
                ),
                const SizedBox(height: 6),
                Text(
                  'Until you turn it off',
                  textAlign: TextAlign.center,
                  style: ZyraText.subtext(size: 13).copyWith(height: 1.5),
                ),
                const SizedBox(height: 20),
                ZyraFloatingSurface(
                  gold: true,
                  radius: 999,
                  child: FilledButton(
                    key: const ValueKey('paused_profiles_show_again'),
                    onPressed: ZyraTapFeedback.onTap(context, onShowProfile),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: BorderSide.none,
                      backgroundColor: ZyraColors.actionFill,
                      foregroundColor: ZyraColors.onAction,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: const StadiumBorder(),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Show my profile again',
                      textAlign: TextAlign.center,
                      style: ZyraText.button(
                        size: 14,
                        color: ZyraColors.onAction,
                      ).copyWith(fontWeight: FontWeight.w500, height: 1.45),
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
