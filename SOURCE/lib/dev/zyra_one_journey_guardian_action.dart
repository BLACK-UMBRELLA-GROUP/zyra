// LOCK 8 V7: presentation only. The admitted shell owns action/route leases.
import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';
import 'zyra_one_journey_monogram_presentation.dart';

class ZyraGuardianActionPage extends StatelessWidget {
  const ZyraGuardianActionPage({
    super.key,
    required this.introduction,
    required this.personName,
    required this.seekerName,
    required this.seekerGender,
    required this.onAction,
  });

  final bool introduction;
  final String personName, seekerName, seekerGender;
  final ValueChanged<String> onAction;

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
    final rows = introduction
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
    name: personName,
    title: introduction
        ? 'Put $personName forward to $seekerName?'
        : '$personName’s Main Guardian',
    eyebrow: introduction ? 'INTRODUCTION' : 'CONNECT WITH GUARDIAN',
  );

  Widget _actions(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ZyraFloatingSurface(
        gold: true,
        radius: 28,
        child: TextButton(
          key: ValueKey(
            'guardian_${introduction ? 'introduce_send' : 'connect_send'}',
          ),
          onPressed: ZyraTapFeedback.onTap(
            context,
            () => onAction(introduction ? 'introduce_send' : 'connect_send'),
          ),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            backgroundColor: ZyraColors.primaryAction,
            foregroundColor: ZyraColors.foreground,
            shape: const StadiumBorder(),
          ),
          child: Text(
            introduction ? 'Introduce' : 'Send request',
            style: ZyraText.body(size: 14, color: ZyraColors.foreground),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        key: const ValueKey('guardian_action_back'),
        onPressed: ZyraTapFeedback.onTap(context, () => onAction('back')),
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: _text(introduction ? 'Not now' : 'Not yet'),
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
              introduction
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
