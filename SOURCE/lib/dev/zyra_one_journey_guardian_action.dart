// LOCK 8 V7: presentation only. The admitted shell owns action/route leases.
import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';
import 'zyra_one_journey_monogram_presentation.dart';
import 'zyra_guardian_family_preview.dart';

class ZyraGuardianActionPage extends StatelessWidget {
  const ZyraGuardianActionPage({
    super.key,
    required this.introduction,
    required this.personName,
    required this.seekerName,
    required this.seekerGender,
    required this.onAction,
    this.canAct,
    this.familyInvite,
  });

  final bool introduction;
  final String personName, seekerName, seekerGender;
  final ValueChanged<String> onAction;
  final bool Function()? canAct;
  final ZyraGuardianFamilyInvite? familyInvite;

  Widget _text(String value, {bool muted = false}) => Text(
    value,
    style: ZyraText.body(
      size: muted ? 12 : 14,
      color: muted ? ZyraColors.ink(.55) : ZyraColors.foreground,
    ).copyWith(height: 1.45),
  );

  Widget _row(IconData icon, String title, String detail) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: ZyraColors.journeyGold),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_text(title), _text(detail, muted: true)],
          ),
        ),
      ],
    ),
  );

  Widget _card() {
    final his = seekerGender.toLowerCase() == 'female' ? 'her' : 'his';
    final invite = familyInvite;
    final rows = invite != null
        ? [
            (
              Icons.workspace_premium_outlined,
              'What Guardian One adds',
              'Chat in ${invite.seekerName}’s Journeys when ${invite.pronoun} turns it on, plus Connect with Guardian and Introductions.',
            ),
            (
              Icons.payments,
              '${invite.seekerName} pays',
              'It’s a place in ${invite.seekerName}’s ZYRA Family. You pay nothing.',
            ),
            (
              Icons.people,
              'Your role stays the same',
              'You stay ${invite.seekerName}’s ${invite.relationship} and ${invite.main ? 'Main' : 'Additional'} Guardian. Chat stays off until ${invite.seekerName} turns it on.',
            ),
            (
              Icons.history,
              'Choose by ${invite.chooseBy}',
              'If you don’t accept, the place stays free for ${invite.seekerName}.',
            ),
          ]
        : introduction
        ? [
            (
              Icons.person_outline,
              '$seekerName sees $personName in $his Introductions',
              'Marked “Suggested by Hassan”.',
            ),
            (
              Icons.send,
              '$seekerName decides',
              'Whether to send a Journey request is $his choice.',
            ),
            (
              Icons.lock_outline,
              '$personName and her family are not told',
              'Nothing is sent to them.',
            ),
          ]
        : [
            (
              Icons.send,
              'Send a request',
              'To the Main Guardian supporting $personName.',
            ),
            (Icons.people, 'They choose', 'Whether to respond is up to them.'),
            (
              Icons.lock_outline,
              'If they accept',
              'A private chat opens between the two of you.',
            ),
          ];
    return ZyraMonogramCard(
      key: const ValueKey('guardian_action_card'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Divider(height: 1, color: ZyraColors.surfaceBorder),
              ),
            _row(rows[i].$1, rows[i].$2, rows[i].$3),
          ],
        ],
      ),
    );
  }

  Widget _head() => ZyraMonogramHead(
    monogramKey: const ValueKey('guardian_action_monogram'),
    name: familyInvite?.seekerName ?? personName,
    title: familyInvite != null
        ? '${familyInvite!.seekerName} has given you Guardian One'
        : introduction
        ? 'Put $personName forward to $seekerName?'
        : '$personName’s Main Guardian',
    eyebrow: familyInvite != null
        ? 'ZYRA FAMILY PLACE'
        : introduction
        ? 'INTRODUCTION'
        : 'CONNECT WITH GUARDIAN',
  );

  Widget _actions(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ZyraFloatingSurface(
        gold: true,
        radius: 28,
        child: TextButton(
          key: ValueKey(
            'guardian_${familyInvite != null
                ? 'family_accept'
                : introduction
                ? 'introduce_send'
                : 'connect_send'}',
          ),
          onPressed: ZyraTapFeedback.onTap(
            context,
            () => onAction(
              familyInvite != null
                  ? 'family_accept'
                  : introduction
                  ? 'introduce_send'
                  : 'connect_send',
            ),
            canAct: canAct,
          ),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            backgroundColor: ZyraColors.primaryAction,
            foregroundColor: ZyraColors.foreground,
            shape: const StadiumBorder(),
          ),
          child: Text(
            familyInvite != null
                ? 'Accept Guardian One'
                : introduction
                ? 'Introduce'
                : 'Send request',
            style: ZyraText.body(size: 14, color: ZyraColors.foreground),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        key: ValueKey(
          familyInvite != null
              ? 'guardian_family_decline'
              : 'guardian_action_back',
        ),
        onPressed: ZyraTapFeedback.onTap(
          context,
          () => onAction(familyInvite != null ? 'family_decline' : 'back'),
          canAct: canAct,
        ),
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: familyInvite != null
            ? Text(
                'Decline',
                style: ZyraText.body(
                  size: 14,
                  color: ZyraColors.dangerText,
                ).copyWith(height: 1.45),
              )
            : _text(introduction ? 'Not now' : 'Not yet'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final scroll =
            MediaQuery.textScalerOf(context).scale(14) > 16 ||
            constraints.maxWidth < 360 ||
            constraints.maxHeight < 740;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: scroll ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Text(
              familyInvite != null
                  ? 'Guardian One'
                  : introduction
                  ? 'Introduce to $seekerName'
                  : 'Connect with Guardian',
              style: ZyraText.heading(
                size: 28,
              ).copyWith(fontWeight: FontWeight.w300, height: 1.2),
            ),
            const SizedBox(height: 28),
            _head(),
            const SizedBox(height: 20),
            _card(),
            if (scroll) const SizedBox(height: 32) else const Spacer(),
            _actions(context),
          ],
        );
        return scroll
            ? ZyraShadowScrollView(
                key: const PageStorageKey('guardian_action_scroll'),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: content,
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: content,
              );
      },
    ),
  );
}

/// LOCK 19 V11 presentation for a detached Founder invitation fixture.
class ZyraGuardianFreePlacePage extends StatelessWidget {
  const ZyraGuardianFreePlacePage({
    super.key,
    required this.canAct,
    required this.onJoin,
    required this.onDismiss,
  });

  final bool Function() canAct;
  final VoidCallback onJoin, onDismiss;

  static const _rows = [
    (
      Icons.people_outline,
      'Adam is on Seeker Basic',
      'One of his Guardians can join on Guardian Basic. That place is already used.',
    ),
    (
      Icons.workspace_premium_outlined,
      'Join on Guardian One',
      'Become Adam’s Guardian now. Chat in his Journeys when he turns it on, plus Connect with Guardian and Introductions.',
    ),
    (
      Icons.history,
      'Or wait for Adam',
      'If Adam moves to Seeker One, his Guardians can join on any plan. Your invitation stays open for 14 days.',
    ),
  ];

  Widget _infoRow(IconData icon, String title, String detail, double padding) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: padding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: ZyraColors.journeyGold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ZyraText.body(size: 14)),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: ZyraText.subtext(size: 12).copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 680;
        final gap = compact ? 12.0 : 20.0;
        return ZyraShadowScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Invitation', style: ZyraText.pageTitle()),
                    SizedBox(height: gap),
                    const ZyraMonogramHead(
                      name: 'Adam',
                      title: 'Adam’s free place is taken',
                      eyebrow: 'GUARDIAN INVITATION',
                      monogramKey: ValueKey('guardian_free_place_monogram'),
                    ),
                    SizedBox(height: gap),
                    Expanded(
                      child: ZyraMonogramCard(
                        key: const ValueKey('guardian_free_place_card'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final (index, (icon, title, detail))
                                in _rows.indexed) ...[
                              if (index > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 38),
                                  child: Divider(
                                    height: 1,
                                    color: ZyraColors.surfaceBorder,
                                  ),
                                ),
                              _infoRow(icon, title, detail, compact ? 10 : 12),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ZyraFloatingSurface(
                      gold: true,
                      radius: 28,
                      child: TextButton(
                        key: const ValueKey('guardian_free_place_join'),
                        onPressed: ZyraTapFeedback.onTap(
                          context,
                          onJoin,
                          canAct: canAct,
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: const StadiumBorder(),
                          backgroundColor: ZyraColors.primaryAction,
                          foregroundColor: ZyraColors.foreground,
                        ),
                        child: Text(
                          'Join with Guardian One',
                          style: ZyraText.body(
                            size: 14,
                          ).copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      key: const ValueKey('guardian_free_place_dismiss'),
                      onPressed: ZyraTapFeedback.onTap(
                        context,
                        onDismiss,
                        canAct: canAct,
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text('Not now', style: ZyraText.body(size: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
